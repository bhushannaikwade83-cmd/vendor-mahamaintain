import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/service_category_model.dart';

class ServiceCategoryRepository {
  Future<List<ServiceCategory>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/categories_list.php'),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch service categories');
    }

    final rawCategories = data['categories'] as List<dynamic>? ?? [];
    return rawCategories.map((c) => ServiceCategory.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<int>> fetchVendorCategoryIds(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/vendor_categories_get.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not fetch your selected categories');
    }

    final rawIds = data['category_ids'] as List<dynamic>? ?? [];
    return rawIds.map((id) => id as int).toList();
  }

  Future<void> saveVendorCategoryIds(String vendorId, List<int> categoryIds) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/vendor_categories_save.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'vendor_id': vendorId, 'category_ids': categoryIds}),
    );

    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error']?.toString() ?? 'Could not save your service categories');
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
