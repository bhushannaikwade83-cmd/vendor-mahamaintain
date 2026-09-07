import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/bank_verification_model.dart';

/// Talks to the PHP backend that holds the Razorpay key/secret and starts a
/// Fund Account Validation (penny-drop) for a vendor's bank account. The
/// Flutter app never talks to Razorpay's server-to-server APIs directly.
class BankVerificationRepository {
  Future<void> startVerification({
    required String vendorId,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/bank_verify_start.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vendor_id': vendorId,
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      }),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not start bank verification');
    }
  }

  Future<BankVerificationInfo> fetchStatus(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/bank_verify_status.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch bank verification status');
    }

    return BankVerificationInfo.fromJson(data);
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
