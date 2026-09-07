import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../models/selfie_verification_model.dart';
import '../repositories/selfie_repository.dart';
import '../widgets/app_toast.dart';

class SelfieVerificationScreen extends ConsumerStatefulWidget {
  const SelfieVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends ConsumerState<SelfieVerificationScreen> {
  final _repository = SelfieRepository();
  final _picker = ImagePicker();

  SelfieVerificationInfo _info = SelfieVerificationInfo.initial();
  XFile? _capturedSelfie;
  bool _loadingStatus = true;
  bool _capturing = false;
  bool _uploading = false;

  String? get _vendorId => ref.read(authRepositoryProvider).getCurrentUserId();

  @override
  void initState() {
    super.initState();
    _refreshStatus();
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _captureSelfie() async {
    setState(() => _capturing = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() => _capturedSelfie = photo);
      }
    } catch (e) {
      if (mounted) showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _submit() async {
    final vendorId = _vendorId;
    final selfie = _capturedSelfie;
    if (vendorId == null || selfie == null) return;

    setState(() => _uploading = true);
    try {
      await _repository.uploadSelfie(vendorId, selfie);
      if (!mounted) return;
      setState(() => _capturedSelfie = null);
      showAppToast(context, 'Selfie submitted for review', type: ToastType.success);
      await _refreshStatus();
    } catch (e) {
      if (mounted) showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Selfie Verification')),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(),
            const SizedBox(height: 20),
            _captureCard(),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    final (label, color, icon, description) = switch (_info.status) {
      SelfieVerificationStatus.approved => (
          'Approved',
          const Color(0xFF059669),
          Icons.verified,
          'Your selfie has been reviewed and approved.',
        ),
      SelfieVerificationStatus.pending => (
          'Pending Review',
          AppTheme.gold,
          Icons.hourglass_top,
          'Your selfie was submitted and is waiting for our team to review it.',
        ),
      SelfieVerificationStatus.rejected => (
          'Rejected',
          const Color(0xFFDC2626),
          Icons.error,
          'Your selfie was rejected. Please retake it - make sure your face is clearly visible.',
        ),
      SelfieVerificationStatus.notSubmitted => (
          'Not Submitted',
          AppTheme.textTertiary,
          Icons.pending_outlined,
          'Take a live selfie so our team can verify it matches your documents.',
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
              ],
            ),
          ),
          if (_loadingStatus)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _captureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Capture Selfie', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Use good lighting and look directly at the camera. Only the front camera is used.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_capturedSelfie != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(_capturedSelfie!.path, height: 220, fit: BoxFit.cover)
                  : Image.file(File(_capturedSelfie!.path), height: 220, fit: BoxFit.cover),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text('📸', style: TextStyle(fontSize: 40)),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _capturing ? null : _captureSelfie,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text(_capturedSelfie == null ? 'Open Camera' : 'Retake Selfie'),
            ),
          ),
          if (_capturedSelfie != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                child: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit for Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
