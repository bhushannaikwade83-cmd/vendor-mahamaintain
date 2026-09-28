import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../repositories/auth_repository.dart' show SupabaseAuthRepository;

class ShopPincodesScreen extends StatefulWidget {
  const ShopPincodesScreen({Key? key}) : super(key: key);

  @override
  State<ShopPincodesScreen> createState() => _ShopPincodesScreenState();
}

class _ShopPincodesScreenState extends State<ShopPincodesScreen> {
  final TextEditingController _pincodeController = TextEditingController();
  List<Map<String, dynamic>> _pincodes = [];
  bool _isLoading = true;
  String? _error;

  static const String API_BASE = 'https://digitrixmedia.com/mahamaintainpro/api';

  @override
  void initState() {
    super.initState();
    _loadPincodes();
  }

  Future<void> _loadPincodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = SupabaseAuthRepository.currentToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Not logged in. Please log in to access pincodes.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$API_BASE/get-vendor-pincodes.php'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pincodes = List<Map<String, dynamic>>.from(data['pincodes'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load pincodes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pincode')),
      );
      return;
    }

    try {
      final token = SupabaseAuthRepository.currentToken;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in. Please log in first.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$API_BASE/add-vendor-pincode.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'pincode': pincode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _pincodeController.clear();
          _loadPincodes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pincode added successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to add pincode')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deletePincode(int id) async {
    try {
      final token = SupabaseAuthRepository.currentToken;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in. Please log in first.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$API_BASE/delete-vendor-pincode.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode == 200) {
        _loadPincodes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pincode removed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop Pincodes'),
        backgroundColor: const Color(0xFFF97316),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add pincode form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Service Area Pincode',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              hintText: 'e.g., 421202',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addPincode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Add Pincode',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // List of pincodes
                  if (_pincodes.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.location_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'No pincodes added yet\nAdd pincodes where you offer services',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pincodes.length,
                      itemBuilder: (context, index) {
                        final pincode = _pincodes[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Color(0xFFF97316)),
                            title: Text(pincode['pincode'],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('Added ${pincode['created_at']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePincode(pincode['id']),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }
}
