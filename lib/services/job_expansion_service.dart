import 'package:logger/logger.dart';
import '../config/supabase_config.dart';
import '../models/nearby_pincode_model.dart';
import '../models/service_request_model.dart';

/// Handles automatic job expansion to nearby pincodes
/// when no vendors accept within the specified time
class JobExpansionService {
  final _supabaseClient = SupabaseConfig.client;
  final _logger = Logger();

  /// Configuration constants
  static const int INITIAL_WAIT_TIME_MINUTES = 5; // Wait 5 min before expanding
  static const int EXPANSION_RADIUS_KM = 10; // Expand to vendors within 10km
  static const int MAX_EXPANSION_ROUNDS = 3; // Maximum expansions (3 times)

  /// Check if a job needs expansion (no vendors accepted yet)
  /// This should be called via a scheduled job or webhook
  Future<bool> checkAndExpandJob(int serviceRequestId) async {
    try {
      final request = await _getServiceRequest(serviceRequestId);
      if (request == null) {
        _logger.w('Service request $serviceRequestId not found');
        return false;
      }

      // Check if job is still unassigned
      if (request.assignedVendorId != null) {
        _logger.i('Job $serviceRequestId already assigned');
        return false;
      }

      // Check if job has been waiting long enough
      final createdAt = DateTime.parse(request.createdAt.toString());
      final waitTime = DateTime.now().difference(createdAt).inMinutes;

      if (waitTime < INITIAL_WAIT_TIME_MINUTES) {
        _logger.i(
          'Job $serviceRequestId waiting for ${INITIAL_WAIT_TIME_MINUTES - waitTime} more minutes before expansion',
        );
        return false;
      }

      // Check expansion history
      final expansionCount = await _getExpansionCount(serviceRequestId);
      if (expansionCount >= MAX_EXPANSION_ROUNDS) {
        _logger.w(
          'Job $serviceRequestId reached max expansions ($MAX_EXPANSION_ROUNDS)',
        );
        // You could mark this as "no_vendors_available" or offer customer refund
        await _markJobForNoVendors(serviceRequestId);
        return false;
      }

      // Expand job to nearby pincodes
      return await expandJobToNearbyPincodes(request, expansionCount + 1);
    } catch (e) {
      _logger.e('Error checking job expansion: $e');
      return false;
    }
  }

  /// Expand job to nearby pincodes
  Future<bool> expandJobToNearbyPincodes(
    ServiceRequest request,
    int expansionRound,
  ) async {
    try {
      _logger.i(
        'Expanding job ${request.id} to nearby pincodes (Round $expansionRound)',
      );

      // Get nearby pincodes
      final nearbyPincodes = await _getNearbyPincodes(
        request.pincode,
        radius: EXPANSION_RADIUS_KM,
        limit: 5, // Get top 5 closest areas
      );

      if (nearbyPincodes.isEmpty) {
        _logger.w('No nearby pincodes found for ${request.pincode}');
        await _markJobForNoVendors(request.id);
        return false;
      }

      // Find vendors in nearby pincodes
      final nearbyVendors = await _getVendorsInNearbyPincodes(
        nearbyPincodes.map((p) => p.pincode).toList(),
        request.serviceCategoryId,
      );

      if (nearbyVendors.isEmpty) {
        _logger.w('No vendors found in nearby pincodes for job ${request.id}');
        if (expansionRound >= MAX_EXPANSION_ROUNDS) {
          await _markJobForNoVendors(request.id);
        }
        return false;
      }

      // Send notifications to nearby vendors
      await _notifyNearbyVendors(
        request,
        nearbyVendors,
        nearbyPincodes,
      );

      // Record expansion in history
      await _recordExpansion(
        request.id,
        request.pincode,
        nearbyPincodes.map((p) => p.pincode).toList(),
        expansionRound,
      );

      _logger.i(
        'Job ${request.id} expanded to ${nearbyVendors.length} vendors in nearby pincodes',
      );

      return true;
    } catch (e) {
      _logger.e('Error expanding job to nearby pincodes: $e');
      return false;
    }
  }

  /// Get nearby pincodes based on distance
  Future<List<NearbyPincode>> _getNearbyPincodes(
    String pincode, {
    required int radius,
    required int limit,
  }) async {
    try {
      // This assumes you have a pincode_mapping or location table
      // that stores pincode coordinates and nearby relationships
      final response = await _supabaseClient
          .from('nearby_pincodes')
          .select()
          .eq('source_pincode', pincode)
          .lte('distance', radius)
          .order('distance', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => NearbyPincode.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Error fetching nearby pincodes: $e');
      return [];
    }
  }

  /// Get vendors in nearby pincodes
  Future<List<Map<String, dynamic>>> _getVendorsInNearbyPincodes(
    List<String> pincodes,
    int serviceCategoryId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('vendor_profiles')
          .select('id, device_token, enrolled_service_ids')
          .inFilter('pincode', pincodes)
          .eq('is_kyc_verified', true)
          .eq('is_bank_verified', true)
          .isFilter('device_token', false);

      // Filter for vendors with matching service
      final vendors = (response as List)
          .where((vendor) {
            final enrolledServices =
                List<int>.from(vendor['enrolled_service_ids'] ?? []);
            return enrolledServices.contains(serviceCategoryId);
          })
          .toList();

      return vendors;
    } catch (e) {
      _logger.e('Error fetching vendors in nearby pincodes: $e');
      return [];
    }
  }

  /// Send notifications to nearby vendors
  Future<void> _notifyNearbyVendors(
    ServiceRequest request,
    List<Map<String, dynamic>> vendors,
    List<NearbyPincode> nearbyPincodes,
  ) async {
    try {
      // Create a mapping of pincode to distance
      final pincodeDistanceMap = {
        for (var p in nearbyPincodes) p.pincode: p.distance
      };

      for (final vendor in vendors) {
        try {
          final vendorPincode = vendor['pincode'];
          final distance = pincodeDistanceMap[vendorPincode] ?? 0.0;

          await _supabaseClient.functions.invoke(
            'send-vendor-notification-expanded',
            body: {
              'vendor_id': vendor['id'],
              'device_token': vendor['device_token'],
              'data': {
                'type': 'expanded_service_request',
                'service_request_id': request.id.toString(),
                'amount': request.budget.toString(),
                'distance': distance.toString(),
                'is_expanded': 'true',
              },
              'notification': {
                'title': 'Job Available Nearby!',
                'body':
                    '₹${request.budget} | ${distance.toStringAsFixed(1)}km away | ${request.locationAddress}',
              },
            },
          );

          // Log notification
          await _logExpansionNotification(
            request.id,
            vendor['id'],
            distance,
          );
        } catch (e) {
          _logger.e('Error notifying vendor: $e');
        }
      }
    } catch (e) {
      _logger.e('Error sending notifications to nearby vendors: $e');
    }
  }

  /// Record job expansion in history
  Future<void> _recordExpansion(
    int jobId,
    String originalPincode,
    List<String> expandedPincodes,
    int expansionRound,
  ) async {
    try {
      await _supabaseClient.from('job_expansions').insert({
        'service_request_id': jobId,
        'original_pincode': originalPincode,
        'expanded_pincodes': expandedPincodes,
        'expansion_round': expansionRound,
        'expanded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error recording expansion: $e');
    }
  }

  /// Log expansion notification sent to vendor
  Future<void> _logExpansionNotification(
    int jobId,
    String vendorId,
    double distance,
  ) async {
    try {
      await _supabaseClient.from('notification_logs').insert({
        'service_request_id': jobId,
        'vendor_id': vendorId,
        'event_type': 'expanded_notification_sent',
        'distance': distance,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Error logging expansion notification: $e');
    }
  }

  /// Get number of times a job has been expanded
  Future<int> _getExpansionCount(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('job_expansions')
          .select()
          .eq('service_request_id', jobId);

      return (response as List).length;
    } catch (e) {
      _logger.e('Error fetching expansion count: $e');
      return 0;
    }
  }

  /// Mark job as "no vendors available" after max expansions
  Future<void> _markJobForNoVendors(int jobId) async {
    try {
      await _supabaseClient
          .from('service_requests')
          .update({
            'status': 'no_vendors_available',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);

      _logger.i('Job $jobId marked as no_vendors_available');
    } catch (e) {
      _logger.e('Error marking job for no vendors: $e');
    }
  }

  /// Get service request by ID
  Future<ServiceRequest?> _getServiceRequest(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('service_requests')
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (response == null) return null;

      return ServiceRequest.fromJson(response);
    } catch (e) {
      _logger.e('Error fetching service request: $e');
      return null;
    }
  }

  /// Get expansion history for a job
  Future<List<JobExpansionHistory>> getExpansionHistory(int jobId) async {
    try {
      final response = await _supabaseClient
          .from('job_expansions')
          .select()
          .eq('service_request_id', jobId)
          .order('expanded_at', ascending: false);

      return (response as List)
          .map((json) => JobExpansionHistory.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Error fetching expansion history: $e');
      return [];
    }
  }
}
