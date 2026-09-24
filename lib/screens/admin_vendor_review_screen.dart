import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../repositories/digilocker_repository.dart';
import '../widgets/app_toast.dart';

class AdminVendorReviewScreen extends ConsumerStatefulWidget {
  const AdminVendorReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminVendorReviewScreen> createState() =>
      _AdminVendorReviewScreenState();
}

class _AdminVendorReviewScreenState
    extends ConsumerState<AdminVendorReviewScreen> {
  final _digiLockerRepo = DigiLockerRepository();
  List<Map<String, dynamic>> _vendors = [];
  bool _loading = true;
  String _filterStatus = 'UNDER_REVIEW';
  int _currentPage = 0;
  int _totalVendors = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadPendingVendors());
  }

  Future<void> _loadPendingVendors({int offset = 0}) async {
    setState(() => _loading = true);

    try {
      final vendors = await _digiLockerRepo.getPendingVendors(
        status: _filterStatus,
        limit: _pageSize,
        offset: offset,
      );

      setState(() {
        _vendors = vendors;
        _currentPage = offset ~/ _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error loading vendors: $e', type: ToastType.error);
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _approveVendor(Map<String, dynamic> vendor) async {
    final confirmed = await _showConfirmDialog(
      'Approve Vendor?',
      'Approve ${vendor['name']} (${vendor['phone']})?',
      'Approve',
    );

    if (!confirmed) return;

    try {
      await _digiLockerRepo.adminVerifyVendor(
        vendorId: vendor['id'].toString(),
        adminName: 'Admin User',
        notes: 'Documents verified and approved',
      );

      if (mounted) {
        showAppToast(context, 'Vendor approved successfully', type: ToastType.success);
        _loadPendingVendors();
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _rejectVendor(Map<String, dynamic> vendor) async {
    final reason = await _showRejectDialog(vendor['name']);
    if (reason == null || reason.isEmpty) return;

    try {
      await _digiLockerRepo.adminRejectVendor(
        vendorId: vendor['id'].toString(),
        rejectionReason: reason,
        adminName: 'Admin User',
      );

      if (mounted) {
        showAppToast(context, 'Vendor rejected', type: ToastType.success);
        _loadPendingVendors();
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error: $e', type: ToastType.error);
      }
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String message,
    String actionButton,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionButton),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _showRejectDialog(String vendorName) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Vendor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor: $vendorName'),
            const SizedBox(height: 16),
            const Text('Rejection Reason:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'E.g., Name mismatch, Invalid documents',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Verification'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: _vendors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No vendors to review',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _vendors.length,
                          itemBuilder: (context, index) =>
                              _buildVendorCard(_vendors[index]),
                        ),
                ),
                _buildPagination(),
              ],
            ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = [
      'UNDER_REVIEW',
      'DIGILOCKER_CONNECTED',
      'UNVERIFIED',
      'REJECTED',
      'VERIFIED'
    ];

    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses
              .map(
                (status) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(status),
                    selected: _filterStatus == status,
                    onSelected: (selected) {
                      setState(() => _filterStatus = status);
                      _loadPendingVendors();
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final documents = vendor['documents'] as List? ?? [];
    final hasAadhaar = documents.any((d) => d['document_type'] == 'ADHAR');
    final hasPan = documents.any((d) => d['document_type'] == 'PANCR');

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vendor['phone'] ?? 'No phone',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (vendor['email'] != null)
                        Text(
                          vendor['email'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(vendor['verification_status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(vendor['verification_status']),
                    ),
                  ),
                  child: Text(
                    vendor['verification_status'] ?? 'UNVERIFIED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(vendor['verification_status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDocumentChecklist(hasAadhaar, hasPan),
            const SizedBox(height: 12),
            if (documents.isNotEmpty) ...[
              const Text(
                'Documents:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...documents.map((doc) => _buildDocumentTile(doc)).toList(),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _rejectVendor(vendor),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _approveVendor(vendor),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentChecklist(bool hasAadhaar, bool hasPan) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasAadhaar ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: hasAadhaar ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                const Text('Aadhaar', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasPan ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: hasPan ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                const Text('PAN', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc['document_type'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (doc['aadhaar_name'] != null)
              Text(
                'Name: ${doc['aadhaar_name']}',
                style: const TextStyle(fontSize: 11),
              ),
            if (doc['aadhaar_number'] != null)
              Text(
                'Aadhaar: ${doc['aadhaar_number']}',
                style: const TextStyle(fontSize: 11),
              ),
            if (doc['pan_name'] != null)
              Text(
                'Name: ${doc['pan_name']}',
                style: const TextStyle(fontSize: 11),
              ),
            if (doc['pan_number'] != null)
              Text(
                'PAN: ${doc['pan_number']}',
                style: const TextStyle(fontSize: 11),
              ),
            if (doc['issue_date'] != null)
              Text(
                'Issued: ${doc['issue_date']}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0
                ? () => _loadPendingVendors(offset: (_currentPage - 1) * _pageSize)
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Text('Page ${_currentPage + 1}'),
          ElevatedButton.icon(
            onPressed: _vendors.length == _pageSize
                ? () => _loadPendingVendors(offset: (_currentPage + 1) * _pageSize)
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'VERIFIED':
        return Colors.green;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'DIGILOCKER_CONNECTED':
        return Colors.blue;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
