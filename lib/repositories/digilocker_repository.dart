import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/vendor_verification_model.dart';

/// Talks to the PHP backend that owns the DigiLocker client secret and the
/// MariaDB verification tables. The Flutter app never talks to DigiLocker
/// directly for the OAuth exchange - it only opens the authorization URL
/// the backend hands back.
class DigiLockerRepository {
  // ===== OAUTH FLOW =====

  Future<String> startVerification(String vendorId) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/digilocker_start.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'vendor_id': vendorId}),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || data['authorization_url'] == null) {
      throw Exception(data['error']?.toString() ?? 'Could not start DigiLocker verification');
    }

    return data['authorization_url'] as String;
  }

  Future<VendorVerificationStatusInfo> fetchStatus(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/verification_status.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch verification status');
    }

    return VendorVerificationStatusInfo.fromJson(data);
  }

  // ===== DOCUMENT MANAGEMENT =====

  Future<List<Map<String, dynamic>>> getStoredDocuments(
    String vendorId, {
    String? documentType,
  }) async {
    final queryParams = {'vendor_id': vendorId};
    if (documentType != null) {
      queryParams['document_type'] = documentType;
    }

    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/get-digilocker-documents.php')
          .replace(queryParameters: queryParams),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch documents');
    }

    final documents = data['documents'] as List?;
    return (documents ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> storeDocuments(
    String vendorId,
    List<Map<String, dynamic>> documents,
  ) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/store-digilocker-documents.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'documents': documents,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || !(data['success'] ?? false)) {
      throw Exception(data['error']?.toString() ?? 'Could not store documents');
    }
  }

  // ===== DATA EXTRACTION =====

  Future<Map<String, dynamic>> extractAadhaarDetails(
    String vendorId,
    Map<String, dynamic> aadhaarData,
  ) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/extract-aadhaar-details.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'aadhaar_data': aadhaarData,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || !(data['success'] ?? false)) {
      throw Exception(data['error']?.toString() ?? 'Could not extract Aadhaar details');
    }

    return data['extracted'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> extractPanDetails(
    String vendorId,
    Map<String, dynamic> panData,
  ) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/extract-pan-details.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'pan_data': panData,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || !(data['success'] ?? false)) {
      throw Exception(data['error']?.toString() ?? 'Could not extract PAN details');
    }

    return {
      'extracted': data['extracted'] as Map<String, dynamic>? ?? {},
      'warning': data['warning'],
    };
  }

  // ===== ADMIN VERIFICATION =====

  Future<void> adminVerifyVendor({
    required String vendorId,
    required String adminName,
    int? adminId,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/admin-verify-vendor.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'admin_id': adminId,
        'admin_name': adminName,
        'notes': notes,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || !(data['success'] ?? false)) {
      throw Exception(data['error']?.toString() ?? 'Could not verify vendor');
    }
  }

  Future<void> adminRejectVendor({
    required String vendorId,
    required String rejectionReason,
    required String adminName,
    int? adminId,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/admin-reject-vendor.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'admin_id': adminId,
        'admin_name': adminName,
        'rejection_reason': rejectionReason,
        'notes': notes,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200 || !(data['success'] ?? false)) {
      throw Exception(data['error']?.toString() ?? 'Could not reject vendor');
    }
  }

  Future<List<Map<String, dynamic>>> getPendingVendors({
    String status = 'UNDER_REVIEW',
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/admin-get-pending-vendors.php')
          .replace(queryParameters: {
        'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch pending vendors');
    }

    final vendors = data['vendors'] as List?;
    return (vendors ?? []).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
