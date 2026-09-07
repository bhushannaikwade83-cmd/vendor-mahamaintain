import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/kyc_backend_config.dart';
import '../models/selfie_verification_model.dart';

class SelfieRepository {
  Future<void> uploadSelfie(String vendorId, XFile selfie) async {
    final uri = Uri.parse('${KycBackendConfig.backendBaseUrl}/selfie_upload.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['vendor_id'] = vendorId
      ..files.add(http.MultipartFile.fromBytes(
        'selfie',
        await selfie.readAsBytes(),
        filename: selfie.name,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not upload selfie');
    }
  }

  Future<SelfieVerificationInfo> fetchStatus(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/selfie_status.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch selfie status');
    }

    return SelfieVerificationInfo.fromJson(data);
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
