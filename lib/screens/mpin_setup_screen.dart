import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import '../repositories/auth_repository.dart';
import '../widgets/app_toast.dart';
import '../widgets/pin_box_row.dart';

/// Shown once, right after the onboarding checklist is complete - the
/// vendor sets a 4-digit M-PIN used to log in on every future visit instead
/// of an OTP.
class MpinSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onMpinSet;

  const MpinSetupScreen({required this.onMpinSet, Key? key}) : super(key: key);

  @override
  ConsumerState<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends ConsumerState<MpinSetupScreen> {
  final _createKey = GlobalKey<PinBoxRowState>();
  final _confirmKey = GlobalKey<PinBoxRowState>();

  String _createdPin = '';
  String _confirmedPin = '';
  bool _showConfirm = false;
  bool _submitting = false;

  void _onCreateChanged(String pin) {
    _createdPin = pin;
    if (pin.length == 4 && !_showConfirm) {
      setState(() => _showConfirm = true);
    }
  }

  Future<void> _onConfirmChanged(String pin) async {
    _confirmedPin = pin;
    if (pin.length != 4 || _submitting) return;

    if (_confirmedPin != _createdPin) {
      showAppToast(context, "PINs don't match - try again", type: ToastType.error);
      _confirmKey.currentState?.clear();
      _createKey.currentState?.clear();
      setState(() {
        _createdPin = '';
        _confirmedPin = '';
        _showConfirm = false;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.setMpin(_createdPin);
      if (!mounted) return;
      if (result is AuthError) {
        showAppToast(context, result.message, type: ToastType.error);
        return;
      }
      widget.onMpinSet();
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              const Text('Create Your M-PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                "You'll use this 4-digit PIN to log in next time instead of an OTP.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 32),
              const Text('Create PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              PinBoxRow(key: _createKey, length: 4, onChanged: _onCreateChanged),
              if (_showConfirm) ...[
                const SizedBox(height: 28),
                const Text('Confirm PIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                PinBoxRow(key: _confirmKey, length: 4, onChanged: _onConfirmChanged),
              ],
              const SizedBox(height: 24),
              if (_submitting) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
