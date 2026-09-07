import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import '../models/selfie_verification_model.dart';
import '../repositories/digilocker_repository.dart';
import '../repositories/selfie_repository.dart';
import '../state/partner_app_state.dart';
import '../widgets/app_toast.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({required this.onDone, Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _digiLockerRepository = DigiLockerRepository();
  final _selfieRepository = SelfieRepository();
  bool _checkingDigiLocker = false;
  bool _checkingSelfie = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && partnerAppState.onboardingProgress < 100) {
        showAppToast(context, 'Complete all steps to unlock full features', type: ToastType.info);
      }
    });
  }

  void _step(int step, String message) {
    partnerAppState.completeOnboardingStep(step);
    setState(() {});
    showAppToast(context, message, type: ToastType.success);
  }

  Future<void> _openDigiLockerVerification() async {
    await context.push('/verification');
    if (!mounted) return;

    final vendorId = ref.read(authRepositoryProvider).getCurrentUserId();
    if (vendorId == null) return;

    setState(() => _checkingDigiLocker = true);
    try {
      final status = await _digiLockerRepository.fetchStatus(vendorId);
      if (!mounted) return;
      if (status.digilockerConnected) {
        _step(1, 'DigiLocker verification submitted - identity & PAN are now under review.');
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _checkingDigiLocker = false);
    }
  }

  Future<void> _openServiceCategories() async {
    final saved = await context.push<bool>('/service-categories');
    if (saved == true) {
      _step(2, 'Service categories saved.');
    }
  }

  Future<void> _openSelfieVerification() async {
    await context.push('/selfie-verification');
    if (!mounted) return;

    final vendorId = ref.read(authRepositoryProvider).getCurrentUserId();
    if (vendorId == null) return;

    setState(() => _checkingSelfie = true);
    try {
      final status = await _selfieRepository.fetchStatus(vendorId);
      if (!mounted) return;
      if (status.status == SelfieVerificationStatus.approved) {
        _step(3, 'Live selfie verified! Partner profile activated.');
      } else if (status.status == SelfieVerificationStatus.pending) {
        // Uploading the selfie is the vendor's part of this step - admin
        // review happens afterward, but the checklist item is done once
        // it's actually been submitted.
        _step(3, 'Selfie submitted for review.');
      }
    } catch (e) {
      if (mounted) showAppToast(context, friendlyErrorMessage(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _checkingSelfie = false);
    }
  }

  Future<void> _finishOnboarding() async {
    // First time through onboarding, the vendor sets an M-PIN they'll use
    // to log in from now on instead of an OTP.
    await context.push('/mpin-setup');
    if (!mounted) return;
    partnerAppState.finishOnboarding();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final progress = partnerAppState.onboardingProgress;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.saffron, AppTheme.saffronDark],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Complete Your Profile',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('3 quick steps • Takes 2 minutes',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.gold]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text('👷', style: TextStyle(fontSize: 38)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Welcome to Maha Maintain Pro Partner!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text("Let's set up your account to start earning",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Onboarding Progress',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('$progress%',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(AppTheme.saffron),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _stepCard(
                      emoji: '🔒',
                      bg: const Color(0xFFDBEAFE),
                      title: 'Identity & PAN (DigiLocker)',
                      subtitle: _checkingDigiLocker
                          ? 'Checking verification status...'
                          : 'Verify Aadhaar & PAN via DigiLocker',
                      done: partnerAppState.digilockerStepDone,
                      onTap: _checkingDigiLocker ? null : _openDigiLockerVerification,
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      emoji: '🛠️',
                      bg: const Color(0xFFFFE3D1),
                      title: 'Service Categories',
                      subtitle: 'Select what you can repair',
                      done: partnerAppState.categoriesStepDone,
                      onTap: _openServiceCategories,
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      emoji: '📸',
                      bg: const Color(0xFFEDE9FE),
                      title: 'Live Selfie Verification',
                      subtitle: _checkingSelfie ? 'Checking verification status...' : 'Capture a live selfie for our team to verify',
                      done: partnerAppState.selfieStepDone,
                      onTap: _checkingSelfie ? null : _openSelfieVerification,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_outlined, size: 18, color: AppTheme.textTertiary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "You'll add and verify your bank account later, from Earnings, right before your first withdrawal.",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.saffron,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Complete Onboarding & Start Earning',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('You can complete remaining steps later from Profile',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({
    required String emoji,
    required Color bg,
    required String title,
    required String subtitle,
    required bool done,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (done)
                        const Text('✓ Verified',
                            style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
