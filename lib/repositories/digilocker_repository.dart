import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/vendor_verification_model.dart';

/// Talks to the PHP backend that owns the DigiLocker client secret and the
/// MariaDB verification tables. The Flutter app never talks to DigiLocker
/// directly for the OAuth exchange - it only opens the authorization URL
/// the backend hands back.
class DigiLockerRepository {
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

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
