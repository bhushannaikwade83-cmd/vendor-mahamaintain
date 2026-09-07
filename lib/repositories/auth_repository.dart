import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/kyc_backend_config.dart';
import '../utils/error_messages.dart';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthLoading extends AuthResult {
  const AuthLoading();
}

/// OTP was correct, but no `vendors` row exists for this phone number yet -
/// the UI needs to collect a name (and optionally email) and call
/// [SupabaseAuthRepository.registerVendor] before the vendor is signed in.
class AuthNeedsRegistration extends AuthResult {
  final String phoneNumber;
  const AuthNeedsRegistration(this.phoneNumber);
}

/// This phone number already has an M-PIN set - no OTP was sent. The UI
/// should show the M-PIN entry screen instead of the OTP screen.
class AuthRequiresMpin extends AuthResult {
  final String phoneNumber;
  const AuthRequiresMpin(this.phoneNumber);
}

class AuthError extends AuthResult {
  final String message;
  const AuthError(this.message);
}

/// Phone number + SMS OTP (first login) or 4-digit M-PIN (every login after
/// that) - backed by send-vendor-otp.php / verify-vendor-otp.php /
/// register-vendor.php / set-vendor-mpin.php / verify-vendor-mpin.php on the
/// shared PHP backend (see server/README.md - these live in the same api/
/// folder as the consumer MahaMaintain Pro app's endpoints). The
/// `vendors.id` returned by the backend doubles as this vendor's id
/// everywhere else in the app (DigiLocker, bank, category and selfie
/// verification).
///
/// The session is persisted to on-device storage so the vendor stays
/// logged in across app restarts - only an explicit Logout tap should ever
/// sign them out. Call [restoreSession] once at app startup before the
/// first route is built.
class SupabaseAuthRepository {
  static const _keyVendorId = 'vendor_id';
  static const _keyVendorName = 'vendor_name';
  static const _keyVendorPhone = 'vendor_phone';
  static const _keyVendorEmail = 'vendor_email';
  static const _keyHasCompletedOnboardingBefore = 'has_completed_onboarding_before';

  String? _vendorId;
  String? _vendorName;
  String? _vendorPhone;
  String? _vendorEmail;

  /// True once this session's login (OTP or M-PIN) resolved to a vendor who
  /// already had an M-PIN set - meaning they finished onboarding on a
  /// previous visit, so the app can skip straight to the dashboard instead
  /// of re-running the onboarding checklist.
  bool hasCompletedOnboardingBefore = false;

  /// Loads a previously persisted session, if any. Call once at app
  /// startup, before the router is built.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _vendorId = prefs.getString(_keyVendorId);
    _vendorName = prefs.getString(_keyVendorName);
    _vendorPhone = prefs.getString(_keyVendorPhone);
    _vendorEmail = prefs.getString(_keyVendorEmail);
    hasCompletedOnboardingBefore = prefs.getBool(_keyHasCompletedOnboardingBefore) ?? false;
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_vendorId != null) await prefs.setString(_keyVendorId, _vendorId!);
    if (_vendorName != null) await prefs.setString(_keyVendorName, _vendorName!);
    if (_vendorPhone != null) await prefs.setString(_keyVendorPhone, _vendorPhone!);
    if (_vendorEmail != null) {
      await prefs.setString(_keyVendorEmail, _vendorEmail!);
    } else {
      await prefs.remove(_keyVendorEmail);
    }
    await prefs.setBool(_keyHasCompletedOnboardingBefore, hasCompletedOnboardingBefore);
  }

  Future<AuthResult> sendOtp(String phoneNumber, {bool forceOtp = false}) async {
    try {
      final response = await http.post(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/send-vendor-otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _tenDigits(phoneNumber),
          if (forceOtp) 'force_otp': true,
        }),
      );
      final data = _decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        return AuthError(data['message']?.toString() ?? 'Could not send OTP');
      }

      if (data['requires_mpin'] == true) {
        return AuthRequiresMpin(phoneNumber);
      }
      return const AuthSuccess();
    } catch (e) {
      return AuthError(friendlyErrorMessage(e));
    }
  }

  Future<AuthResult> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/verify-vendor-otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': _tenDigits(phoneNumber), 'otp': otp}),
      );
      final data = _decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        return AuthError(data['message']?.toString() ?? 'Invalid OTP');
      }

      if (data['exists'] == true) {
        _vendorId = data['vendor_id'].toString();
        _vendorName = data['name'] as String?;
        _vendorEmail = data['email'] as String?;
        _vendorPhone = _tenDigits(phoneNumber);
        hasCompletedOnboardingBefore = data['has_mpin'] == true;
        await _persistSession();
        return const AuthSuccess();
      }
      return AuthNeedsRegistration(phoneNumber);
    } catch (e) {
      return AuthError(friendlyErrorMessage(e));
    }
  }

  Future<AuthResult> verifyMpin(String phoneNumber, String mpin) async {
    try {
      final response = await http.post(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/verify-vendor-mpin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': _tenDigits(phoneNumber), 'mpin': mpin}),
      );
      final data = _decode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        return AuthError(data['message']?.toString() ?? 'Incorrect M-PIN');
      }

      _vendorId = data['vendor_id'].toString();
      _vendorName = data['name'] as String?;
      _vendorEmail = data['email'] as String?;
      _vendorPhone = _tenDigits(phoneNumber);
      hasCompletedOnboardingBefore = true;
      await _persistSession();
      return const AuthSuccess();
    } catch (e) {
      return AuthError(friendlyErrorMessage(e));
    }
  }

  /// Called once, right after the onboarding checklist is complete.
  Future<AuthResult> setMpin(String mpin) async {
    final vendorId = _vendorId;
    if (vendorId == null) {
      return const AuthError('Please sign in again to continue');
    }

    try {
      final response = await http.post(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/set-vendor-mpin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vendor_id': vendorId, 'mpin': mpin}),
      );
      final data = _decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        hasCompletedOnboardingBefore = true;
        await _persistSession();
        return const AuthSuccess();
      }
      return AuthError(data['message']?.toString() ?? 'Could not set M-PIN');
    } catch (e) {
      return AuthError(friendlyErrorMessage(e));
    }
  }

  /// Called after [AuthNeedsRegistration] - creates the `vendors` row.
  Future<AuthResult> registerVendor({
    required String phoneNumber,
    required String name,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/register-vendor.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _tenDigits(phoneNumber),
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        }),
      );
      final data = _decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _vendorId = data['vendor_id'].toString();
        _vendorName = name;
        _vendorEmail = email;
        _vendorPhone = _tenDigits(phoneNumber);
        await _persistSession();
        return const AuthSuccess();
      }
      return AuthError(data['message']?.toString() ?? 'Could not complete registration');
    } catch (e) {
      return AuthError(friendlyErrorMessage(e));
    }
  }

  Future<AuthResult> resendOtp(String phoneNumber) => sendOtp(phoneNumber);

  Future<void> logout() async {
    _vendorId = null;
    _vendorName = null;
    _vendorPhone = null;
    _vendorEmail = null;
    hasCompletedOnboardingBefore = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVendorId);
    await prefs.remove(_keyVendorName);
    await prefs.remove(_keyVendorPhone);
    await prefs.remove(_keyVendorEmail);
    await prefs.remove(_keyHasCompletedOnboardingBefore);
  }

  String? getCurrentUserId() => _vendorId;

  String? getCurrentVendorName() => _vendorName;

  String? getCurrentVendorPhone() => _vendorPhone;

  String? getCurrentVendorEmail() => _vendorEmail;

  bool isAuthenticated() => _vendorId != null;

  String _tenDigits(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
