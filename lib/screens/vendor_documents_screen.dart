import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../repositories/digilocker_repository.dart';
import '../widgets/app_toast.dart';

class VendorDocumentsScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDocumentsScreen({
    required this.vendorId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<VendorDocumentsScreen> createState() =>
      _VendorDocumentsScreenState();
}

class _VendorDocumentsScreenState extends ConsumerState<VendorDocumentsScreen> {
  final _digiLockerRepo = DigiLockerRepository();
  List<Map<String, dynamic>> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadDocuments());
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);

    try {
      final docs = await _digiLockerRepo.getStoredDocuments(widget.vendorId);
      setState(() {
        _documents = docs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          'Error loading documents: $e',
          type: ToastType.error,
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stored Documents'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents stored yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadDocuments,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Total Documents: ${_documents.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._documents
                            .map((doc) => _buildDocumentCard(doc))
                            .toList(),
                      ],
                    ),
            ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = doc['document_type'] as String? ?? 'Unknown';
    final isAadhaar = docType == 'ADHAR';
    final isPan = docType == 'PANCR';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDocTypeIcon(docType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${doc['document_id'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isAadhaar) ...[
              _buildDetailRow('Name', doc['aadhaar_name']),
              _buildDetailRow('Number', doc['aadhaar_number'] ?? 'Masked'),
              _buildDetailRow('Date of Birth', doc['aadhaar_dob']),
              _buildDetailRow('Gender', doc['aadhaar_gender']),
            ] else if (isPan) ...[
              _buildDetailRow('Name', doc['pan_name']),
              _buildDetailRow('PAN Number', doc['pan_number'] ?? 'Masked'),
              _buildDetailRow('Father Name', doc['pan_father_name']),
              _buildDetailRow('Date of Birth', doc['pan_dob']),
            ],
            if (doc['issue_date'] != null || doc['expiry_date'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (doc['issue_date'] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issued',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              doc['issue_date'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (doc['expiry_date'] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              doc['expiry_date'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Stored: ${doc['created_at'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeIcon(String docType) {
    IconData icon;
    Color color;

    switch (docType) {
      case 'ADHAR':
        icon = Icons.verified_user;
        color = AppTheme.teal;
        break;
      case 'PANCR':
        icon = Icons.card_membership;
        color = AppTheme.gold;
        break;
      case 'DRIVINGLICENSE':
        icon = Icons.directions_car;
        color = Colors.blue;
        break;
      default:
        icon = Icons.document_scanner;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
