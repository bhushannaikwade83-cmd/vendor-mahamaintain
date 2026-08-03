import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../state/partner_app_state.dart';
import '../widgets/app_toast.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({required this.onDone, Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Complete Your Profile',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Step 1 of 5 • Takes 2 minutes',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDone,
                    child: const Text('Skip for Demo',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
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
                    const Text('Welcome to Channel Partners!',
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
                      emoji: '📄',
                      bg: const Color(0xFFDBEAFE),
                      title: 'Aadhaar & PAN',
                      subtitle: 'Upload documents for KYC',
                      done: progress >= 80,
                      onTap: () => _step(1, 'Aadhaar & PAN uploaded successfully (Demo). Documents verified!'),
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      emoji: '🏦',
                      bg: const Color(0xFFD1FAE5),
                      title: 'Bank Account',
                      subtitle: 'For instant payouts',
                      done: progress >= 90,
                      onTap: () => _step(2, 'Bank account linked with UPI (Demo). Ready for instant payouts.'),
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      emoji: '🛠️',
                      bg: const Color(0xFFFFE3D1),
                      title: 'Service Categories',
                      subtitle: 'Select what you can repair',
                      done: progress >= 95,
                      onTap: () => _step(3, 'Services updated: Electrician, Plumber, AC Repair, etc.'),
                    ),
                    const SizedBox(height: 12),
                    _stepCard(
                      emoji: '📸',
                      bg: const Color(0xFFEDE9FE),
                      title: 'Live Selfie Verification',
                      subtitle: 'Quick video KYC',
                      done: progress >= 100,
                      onTap: () => _step(4, 'Live selfie verified! Partner profile activated.'),
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
                      onPressed: () {
                        partnerAppState.finishOnboarding();
                        widget.onDone();
                      },
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
    required VoidCallback onTap,
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
