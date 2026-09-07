import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/society_model.dart';

class SocietyRepository {
  Future<List<Society>> fetchSocieties() async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/societies_list.php'),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch societies');
    }

    final raw = data['societies'] as List<dynamic>? ?? [];
    return raw.map((s) => Society.fromJson(s as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
