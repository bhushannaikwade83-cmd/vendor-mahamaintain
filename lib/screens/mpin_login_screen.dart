import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import '../repositories/auth_repository.dart';
import '../widgets/app_toast.dart';
import '../widgets/pin_box_row.dart';

class MpinLoginScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerificationSuccess;
  final void Function(String phoneNumber) onUseOtpInstead;
  final VoidCallback onBackPress;

  const MpinLoginScreen({
    required this.phoneNumber,
    required this.onVerificationSuccess,
    required this.onUseOtpInstead,
    required this.onBackPress,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MpinLoginScreen> createState() => _MpinLoginScreenState();
}

class _MpinLoginScreenState extends ConsumerState<MpinLoginScreen> {
  final _pinKey = GlobalKey<PinBoxRowState>();
  bool _isVerifying = false;
  bool _isRequestingOtp = false;

  Future<void> _verify(String pin) async {
    if (pin.length != 4 || _isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.verifyMpin(widget.phoneNumber, pin);
      if (!mounted) return;
      if (result is AuthError) {
        showAppToast(context, result.message, type: ToastType.error);
        _pinKey.currentState?.clear();
        return;
      }
      widget.onVerificationSuccess();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _useOtpInstead() async {
    setState(() => _isRequestingOtp = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.sendOtp(widget.phoneNumber, forceOtp: true);
      if (!mounted) return;
      if (result is AuthError) {
        showAppToast(context, result.message, type: ToastType.error);
        return;
      }
      widget.onUseOtpInstead(widget.phoneNumber);
    } finally {
      if (mounted) setState(() => _isRequestingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBackPress,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.saffron, AppTheme.gold]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              const Text('Enter Your M-PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Welcome back, ${widget.phoneNumber}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              PinBoxRow(
                key: _pinKey,
                length: 4,
                onChanged: _verify,
              ),
              const SizedBox(height: 24),
              if (_isVerifying)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: TextButton(
                    onPressed: _isRequestingOtp ? null : _useOtpInstead,
                    child: _isRequestingOtp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Forgot M-PIN? Login with OTP instead'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
