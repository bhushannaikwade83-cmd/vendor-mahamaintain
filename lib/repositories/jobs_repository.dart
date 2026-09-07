import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/earnings_model.dart';
import '../models/job_models.dart';

class VendorJobsSnapshot {
  final List<Job> newJobs;
  final List<Job> myJobs;
  VendorJobsSnapshot({required this.newJobs, required this.myJobs});
}

class JobActionException implements Exception {
  final String message;
  JobActionException(this.message);
  @override
  String toString() => message;
}

class JobsRepository {
  Future<VendorJobsSnapshot> fetchJobs(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-jobs.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw JobActionException(data['error']?.toString() ?? 'Could not load jobs');
    }
    return VendorJobsSnapshot(
      newJobs: ((data['new_jobs'] as List?) ?? []).map((e) => Job.fromJson(e as Map<String, dynamic>)).toList(),
      myJobs: ((data['my_jobs'] as List?) ?? []).map((e) => Job.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> respondToJob(String vendorId, int bookingId, {required bool accept}) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/respond-to-job.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'booking_id': bookingId,
        'action': accept ? 'accept' : 'reject',
      }),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not respond to job');
    }
  }

  Future<void> startJob(String vendorId, int bookingId, {File? beforePhoto}) async {
    await _updateStatus(vendorId, bookingId, 'start', photoField: 'before_photo', photo: beforePhoto);
  }

  Future<void> completeJob(String vendorId, int bookingId, String completionOtp, {File? afterPhoto}) async {
    await _updateStatus(
      vendorId,
      bookingId,
      'complete',
      photoField: 'after_photo',
      photo: afterPhoto,
      extraFields: {'completion_otp': completionOtp},
    );
  }

  Future<void> cancelJob(String vendorId, int bookingId) async {
    await _updateStatus(vendorId, bookingId, 'cancel');
  }

  Future<void> _updateStatus(
    String vendorId,
    int bookingId,
    String action, {
    String? photoField,
    File? photo,
    Map<String, String>? extraFields,
  }) async {
    final uri = Uri.parse('${KycBackendConfig.backendBaseUrl}/update-job-status.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['vendor_id'] = vendorId
      ..fields['booking_id'] = bookingId.toString()
      ..fields['action'] = action;
    if (extraFields != null) request.fields.addAll(extraFields);
    if (photoField != null && photo != null) {
      request.files.add(await http.MultipartFile.fromPath(photoField, photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not update job');
    }
  }

  Future<VendorEarnings> fetchEarnings(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-earnings.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw JobActionException(data['error']?.toString() ?? 'Could not load earnings');
    }
    return VendorEarnings.fromJson(data);
  }

  Future<void> setOnlineStatus(String vendorId, bool isOnline) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/set-vendor-online-status.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'vendor_id': vendorId, 'is_online': isOnline}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not update online status');
    }
  }

  Future<void> withdraw(String vendorId, double amount) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/withdraw-earnings.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'vendor_id': vendorId, 'amount': amount}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not process withdrawal');
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
