import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../repositories/auth_repository.dart';

class JobCompletionScreen extends StatefulWidget {
  final int orderId;
  final String customerName;
  final String serviceTitle;
  final double totalAmount;

  const JobCompletionScreen({
    required this.orderId,
    required this.customerName,
    required this.serviceTitle,
    required this.totalAmount,
    Key? key,
  }) : super(key: key);

  @override
  State<JobCompletionScreen> createState() => _JobCompletionScreenState();
}

class _JobCompletionScreenState extends State<JobCompletionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _beforePhoto;
  File? _afterPhoto;
  final TextEditingController _workDescriptionController = TextEditingController();
  final TextEditingController _partsUsedController = TextEditingController();
  final TextEditingController _additionalChargesController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _pickImage(bool isBefore) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isBefore) {
            _beforePhoto = File(image.path);
          } else {
            _afterPhoto = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _submitCompletion() async {
    if (_beforePhoto == null || _afterPhoto == null) {
      _showError('Before & After photos are required');
      return;
    }

    if (_workDescriptionController.text.isEmpty) {
      _showError('Please describe the work done');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload before photo
      final beforeResponse = await _uploadPhoto(_beforePhoto!, 'before_${widget.orderId}');
      if (!beforeResponse['success']) {
        throw Exception('Failed to upload before photo');
      }

      // Upload after photo
      final afterResponse = await _uploadPhoto(_afterPhoto!, 'after_${widget.orderId}');
      if (!afterResponse['success']) {
        throw Exception('Failed to upload after photo');
      }

      // Create job completion report
      final reportResponse = await http.post(
        Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/vendor/complete-job.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
        body: jsonEncode({
          'order_id': widget.orderId,
          'before_photo': beforeResponse['photo_url'],
          'after_photo': afterResponse['photo_url'],
          'work_description': _workDescriptionController.text,
          'parts_used': _partsUsedController.text,
          'additional_charges': double.tryParse(_additionalChargesController.text) ?? 0,
          'remarks': _remarksController.text,
        }),
      );

      if (reportResponse.statusCode == 200) {
        final data = jsonDecode(reportResponse.body);
        if (data['success']) {
          _showSuccess('Job completed successfully!');
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, dynamic>> _uploadPhoto(File file, String name) async {
    try {
      final uri = Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/upload-job-photo.php');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('photo', file.path));
      request.fields['order_id'] = widget.orderId.toString();
      request.fields['photo_name'] = name;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      return {
        'success': data['success'] ?? false,
        'photo_url': data['photo_url'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'photo_url': ''};
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Job'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${widget.orderId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Customer: ${widget.customerName}', style: const TextStyle(fontSize: 12)),
                    Text('Service: ${widget.serviceTitle}', style: const TextStyle(fontSize: 12)),
                    Text('Amount: ₹${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Before Photo
              const Text('Before Photo *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoUploadSection(_beforePhoto, true),
              const SizedBox(height: 24),

              // After Photo
              const Text('After Photo *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoUploadSection(_afterPhoto, false),
              const SizedBox(height: 24),

              // Work Description
              const Text('Work Description *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _workDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the work done...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),

              // Parts Used
              const Text('Parts Used', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _partsUsedController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'List any parts or materials used...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),

              // Additional Charges
              const Text('Additional Charges (₹)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _additionalChargesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 24),

              // Remarks
              const Text('Remarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any additional remarks...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCompletion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Completion Report',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection(File? photo, bool isBefore) {
    return GestureDetector(
      onTap: () => _pickImage(isBefore),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          image: photo != null
              ? DecorationImage(image: FileImage(photo), fit: BoxFit.cover)
              : null,
        ),
        child: photo == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to capture photo',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
