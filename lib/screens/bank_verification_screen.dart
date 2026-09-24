import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../models/bank_verification_model.dart';
import '../repositories/bank_verification_repository.dart';
import '../widgets/app_toast.dart';

class BankVerificationScreen extends ConsumerStatefulWidget {
  const BankVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends ConsumerState<BankVerificationScreen> {
  final _repository = BankVerificationRepository();
  final _formKey = GlobalKey<FormState>();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscController = TextEditingController();

  BankVerificationInfo _info = BankVerificationInfo.initial();
  bool _loadingStatus = true;
  bool _submitting = false;
  Timer? _pollTimer;

  String? get _vendorId => ref.read(authRepositoryProvider).getCurrentUserId();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final vendorId = _vendorId;
    if (vendorId == null) return;

    setState(() => _loadingStatus = true);
    try {
      final info = await _repository.fetchStatus(vendorId);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadingStatus = false;
      });
      if (info.status == BankVerificationStatus.pending) {
        _startPolling();
      } else {
        _pollTimer?.cancel();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStatus = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshStatus());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vendorId = _vendorId;
    if (vendorId == null) {
      showAppToast(context, 'Please sign in again to continue', type: ToastType.error);
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repository.startVerification(
        vendorId: vendorId,
        accountHolderName: _holderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
      );
      await _refreshStatus();
    } catch (e) {
      if (mounted) showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Account Verification')),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(),
            const SizedBox(height: 20),
            if (_info.status != BankVerificationStatus.verified) _form(),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    final (label, color, icon, description) = switch (_info.status) {
      BankVerificationStatus.verified => (
          'Verified',
          const Color(0xFF059669),
          Icons.verified,
          _info.nameMatch == false
              ? 'Account verified, but the registered name did not closely match "${_info.accountHolderName}". Your team may want to double-check this.'
              : 'Your bank account is verified and ready for payouts.',
        ),
      BankVerificationStatus.pending => (
          'Verifying...',
          AppTheme.gold,
          Icons.hourglass_top,
          'We sent a small verification credit to confirm your account. This usually takes a minute.',
        ),
      BankVerificationStatus.failed => (
          'Verification Failed',
          const Color(0xFFDC2626),
          Icons.error,
          'We could not verify this account. Double-check the details and try again.',
        ),
      BankVerificationStatus.notSubmitted => (
          'Not Verified',
          AppTheme.textTertiary,
          Icons.pending_outlined,
          'Add your bank details below to get verified for payouts.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                if (_info.accountNumberLast4 != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Account ending in ${_info.accountNumberLast4} • ${_info.ifscCode ?? ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ],
            ),
          ),
          if (_loadingStatus)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bank Account Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'We verify this account with a small refundable credit before marking it verified.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(labelText: 'Account Holder Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Account Number'),
              validator: (v) => (v == null || v.trim().length < 6) ? 'Enter a valid account number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmAccountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Confirm Account Number'),
              validator: (v) =>
                  v != _accountNumberController.text ? 'Account numbers do not match' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ifscController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'IFSC Code'),
              validator: (v) {
                final value = (v ?? '').trim().toUpperCase();
                final valid = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value);
                return valid ? null : 'Enter a valid IFSC code';
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_info.status == BankVerificationStatus.failed ? 'Retry Verification' : 'Verify Bank Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
