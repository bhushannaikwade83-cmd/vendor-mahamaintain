import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../main.dart';
import '../models/vendor_verification_model.dart';
import '../repositories/digilocker_repository.dart';
import '../widgets/app_toast.dart';

class VendorVerificationScreen extends ConsumerStatefulWidget {
  const VendorVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VendorVerificationScreen> createState() => _VendorVerificationScreenState();
}

class _VendorVerificationScreenState extends ConsumerState<VendorVerificationScreen>
    with WidgetsBindingObserver {
  final _digiLockerRepository = DigiLockerRepository();

  VendorVerificationStatusInfo _info = VendorVerificationStatusInfo.initial();
  bool _loadingStatus = true;
  bool _startingVerification = false;
  String? _statusError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Vendor returns to the app from the DigiLocker browser tab - pull the
    // latest status the backend recorded from the OAuth callback.
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  String? get _vendorId => ref.read(authRepositoryProvider).getCurrentUserId();

  Future<void> _refreshStatus() async {
    final vendorId = _vendorId;
    if (vendorId == null) return;

    setState(() {
      _loadingStatus = true;
      _statusError = null;
    });

    try {
      final info = await _digiLockerRepository.fetchStatus(vendorId);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = friendlyErrorMessage(e);
        _loadingStatus = false;
      });
    }
  }

  Future<void> _startVerification() async {
    debugPrint('🔵 [DigiLocker] _startVerification() called');

    final vendorId = _vendorId;
    debugPrint('🔵 [DigiLocker] vendorId: $vendorId');

    if (vendorId == null) {
      debugPrint('❌ [DigiLocker] vendorId is null');
      showAppToast(context, 'Please sign in again to continue', type: ToastType.error);
      return;
    }

    setState(() => _startingVerification = true);

    try {
      debugPrint('🔵 [DigiLocker] Calling startVerification() API...');
      final authorizationUrl = await _digiLockerRepository.startVerification(vendorId);
      debugPrint('🟢 [DigiLocker] Got authorization URL: $authorizationUrl');

      final uri = Uri.parse(authorizationUrl);
      debugPrint('🔵 [DigiLocker] Parsed URI: $uri');

      debugPrint('🔵 [DigiLocker] Launching URL...');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('🔵 [DigiLocker] launchUrl result: $launched');

      if (!launched && mounted) {
        debugPrint('❌ [DigiLocker] Failed to launch URL');
        showAppToast(context, 'Could not open DigiLocker', type: ToastType.error);
      } else if (launched && mounted) {
        debugPrint('🟢 [DigiLocker] URL launched successfully, waiting for callback...');
      }
    } catch (e) {
      debugPrint('❌ [DigiLocker] Error: $e');
      if (mounted) {
        showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _startingVerification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Verification')),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(),
            const SizedBox(height: 20),
            _digiLockerCard(),
            const SizedBox(height: 20),
            const Text('Document Checks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _docTile('Identity (Aadhaar)', _info.identityVerified),
            _docTile('PAN', _info.panVerified),
            const SizedBox(height: 20),
            if (_statusError != null)
              Text(
                'Could not load verification status: $_statusError',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    final (label, color, icon) = switch (_info.status) {
      VendorVerificationStatus.verified => ('Verified', const Color(0xFF059669), Icons.verified),
      VendorVerificationStatus.underReview => ('Under Review', AppTheme.gold, Icons.hourglass_top),
      VendorVerificationStatus.digilockerConnected => (
          'DigiLocker Connected',
          AppTheme.teal,
          Icons.link,
        ),
      VendorVerificationStatus.rejected => ('Rejected', const Color(0xFFDC2626), Icons.error),
      VendorVerificationStatus.unverified => ('Not Verified', AppTheme.textTertiary, Icons.pending_outlined),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                const Text(
                  'Verification status is set by our team after reviewing your DigiLocker documents.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_loadingStatus)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _digiLockerCard() {
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.saffron50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🔒', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Verify with DigiLocker', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Securely verify your identity and documents using your Aadhaar-linked '
            'DigiLocker account. You will be taken to DigiLocker\'s own sign-in page '
            'to authenticate and allow access - we never see your Aadhaar number or '
            'DigiLocker PIN.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startingVerification ? null : _startVerification,
              icon: _startingVerification
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.open_in_new, size: 18),
              label: Text(_info.digilockerConnected ? 'Re-verify with DigiLocker' : 'Verify with DigiLocker'),
            ),
          ),
          if (_info.digilockerConnected) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _loadingStatus ? null : _refreshStatus,
                child: const Text('Refresh status', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _docTile(String label, bool verified) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: verified ? const Color(0xFF059669) : AppTheme.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            verified ? 'Verified' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: verified ? const Color(0xFF059669) : AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
