import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';

import '../main.dart' show authRepositoryProvider;

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerificationSuccess;
  final VoidCallback onBackPress;

  const OtpScreen({
    required this.phoneNumber,
    required this.onVerificationSuccess,
    required this.onBackPress,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  int _resendCountdown = 30;
  bool _canResend = false;
  bool _isVerifying = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _otpFocused = false;
  final FocusNode _otpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );
    _animationController.forward();
    _startResendCountdown();
    _otpFocus.addListener(() {
      setState(() => _otpFocused = _otpFocus.hasFocus);
    });
  }

  void _startResendCountdown() {
    _resendCountdown = 30;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
      }
      return _resendCountdown > 0 && mounted;
    }).then((_) {
      if (mounted) setState(() => _canResend = true);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _animationController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    setState(() => _isVerifying = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.verifyOtp(phoneNumber, _otpController.text);
      onVerificationSuccess();
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  void _resendOtp() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.resendOtp(phoneNumber);
    _otpController.clear();
    _startResendCountdown();
  }

  String get phoneNumber => widget.phoneNumber;
  VoidCallback get onVerificationSuccess => widget.onVerificationSuccess;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return WillPopScope(
      onWillPop: () async {
        widget.onBackPress();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.saffron,
                          AppTheme.saffron.withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.saffron.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + (isSmall ? 16 : 24),
                      bottom: isSmall ? 32 : 40,
                      left: 24,
                      right: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: 1,
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              '🏙️',
                              style: TextStyle(
                                fontSize: isSmall ? 40 : 48,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 16 : 20),
                        Text(
                          'MahaMaintain',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: isSmall ? 8 : 12),
                        Text(
                          'महाराष्ट्र का विश्वास',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmall ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmall ? 20 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 3,
                          width: _otpFocused ? 60 : 40,
                          color: AppTheme.saffron,
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text(
                          'Verify Phone Number',
                          style: TextStyle(
                            fontSize: isSmall ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'OTP sent to $phoneNumber',
                          style: TextStyle(
                            fontSize: isSmall ? 13 : 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: isSmall ? 24 : 32),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: _otpFocused
                                  ? AppTheme.saffron
                                  : Colors.grey.shade200,
                              width: _otpFocused ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _otpFocused
                                ? [
                                    BoxShadow(
                                      color: AppTheme.saffron.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: TextField(
                            controller: _otpController,
                            focusNode: _otpFocus,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmall ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade300,
                                letterSpacing: 6,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_otpController.text.length}/6',
                            style: TextStyle(
                              fontSize: isSmall ? 11 : 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 24 : 32),
                        AnimatedScale(
                          scale: _otpController.text.length == 6 ? 1.02 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            width: double.infinity,
                            height: isSmall ? 50 : 56,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _otpController.text.length == 6 &&
                                        !_isVerifying
                                    ? _verifyOtp
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.saffron.withOpacity(0.9),
                                        AppTheme.saffron.withOpacity(0.75),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.saffron.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isVerifying
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation(
                                                Colors.white.withOpacity(0.8),
                                              ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verify & Login',
                                                style: TextStyle(
                                                  fontSize: isSmall ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 20 : 24),
                        AnimatedOpacity(
                          opacity: 1,
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive OTP? ",
                                style: TextStyle(
                                  fontSize: isSmall ? 13 : 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_canResend)
                                GestureDetector(
                                  onTap: _resendOtp,
                                  child: Text(
                                    'Resend',
                                    style: TextStyle(
                                      fontSize: isSmall ? 13 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.saffron,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  'Resend in ${_resendCountdown}s',
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.saffron,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmall ? 12 : 16),
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onBackPress,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.teal.withOpacity(0.2),
                                      AppTheme.teal.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.teal.withOpacity(0.4),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.teal.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Change Phone Number',
                                  style: TextStyle(
                                    fontSize: isSmall ? 13 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.teal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
