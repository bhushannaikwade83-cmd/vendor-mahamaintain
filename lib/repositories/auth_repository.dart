import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthLoading extends AuthResult {
  const AuthLoading();
}

class AuthError extends AuthResult {
  final String message;
  const AuthError(this.message);
}

class SupabaseAuthRepository {
  // Demo mode flag - set to false to use real Supabase
  static const bool DEMO_MODE = true;

  String? _demoUserId;
  String? _demoOtp;

  final SupabaseClient _client = SupabaseConfig.client;

  Future<AuthResult> sendOtp(String phoneNumber) async {
    if (DEMO_MODE) {
      // Generate dummy OTP for demo
      _demoOtp = '123456';
      _demoUserId = phoneNumber;
      return const AuthSuccess();
    }

    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
      return const AuthSuccess();
    } on AuthException catch (e) {
      return AuthError(e.message);
    } catch (e) {
      return AuthError(e.toString());
    }
  }

  Future<AuthResult> verifyOtp(String phoneNumber, String otp) async {
    if (DEMO_MODE) {
      // In demo mode, accept any 6-digit OTP
      if (otp.length == 6) {
        return const AuthSuccess();
      }
      return const AuthError('Please enter a valid 6-digit OTP');
    }

    try {
      final response = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );

      if (response.session != null) {
        return const AuthSuccess();
      } else {
        return const AuthError('Verification failed');
      }
    } on AuthException catch (e) {
      return AuthError(e.message);
    } catch (e) {
      return AuthError(e.toString());
    }
  }

  Future<AuthResult> resendOtp(String phoneNumber) async {
    if (DEMO_MODE) {
      _demoOtp = '123456';
      return const AuthSuccess();
    }

    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );
      return const AuthSuccess();
    } on AuthException catch (e) {
      return AuthError(e.message);
    } catch (e) {
      return AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    if (!DEMO_MODE) {
      await _client.auth.signOut();
    }
    _demoUserId = null;
    _demoOtp = null;
  }

  String? getCurrentUserId() {
    if (DEMO_MODE) {
      return _demoUserId ?? 'demo_user_123';
    }
    return _client.auth.currentUser?.id;
  }

  String? getCurrentToken() {
    if (DEMO_MODE) {
      return 'demo_token_xyz';
    }
    return _client.auth.currentSession?.accessToken;
  }

  bool isAuthenticated() {
    if (DEMO_MODE) {
      return _demoUserId != null;
    }
    return _client.auth.currentUser != null;
  }

  String? getDemoOtp() => _demoOtp;

  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }
}
