import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/mpin_login_screen.dart';
import '../screens/mpin_setup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/vendor_registration_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/vendor_verification_screen.dart';
import '../screens/bank_verification_screen.dart';
import '../screens/service_categories_screen.dart';
import '../screens/selfie_verification_screen.dart';
import '../state/partner_app_state.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  static bool _authenticated = false;

  // KYC + M-PIN setup sub-screens the onboarding flow pushes to (DigiLocker,
  // bank, categories, selfie, mpin-setup). These must stay reachable even
  // while onboarding is incomplete, otherwise the router bounces straight
  // back to /onboarding the instant they're opened.
  static const List<String> _kycRoutes = [
    '/verification',
    '/bank-verification',
    '/service-categories',
    '/selfie-verification',
    '/mpin-setup',
  ];

  static GoRouter createRouter(SupabaseAuthRepository authRepository) {
    return GoRouter(
      redirect: (context, state) async {
        final isAuthenticated = authRepository.isAuthenticated();
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp' ||
            state.matchedLocation == '/mpin-login' ||
            state.matchedLocation == '/register-vendor';

        // Authentication is checked FIRST, before the login-flow bypass
        // below - a restored session (app restart, not a real logout)
        // still lands on /login as GoRouter's initialLocation, and an
        // already-authenticated vendor must be sent straight on to
        // onboarding/dashboard from there instead of being made to log in
        // again via OTP/M-PIN.
        if (isAuthenticated) {
          if (!partnerAppState.onboardingCompleted &&
              state.matchedLocation != '/onboarding' &&
              !_kycRoutes.contains(state.matchedLocation)) {
            return '/onboarding';
          }
          if (partnerAppState.onboardingCompleted &&
              (state.matchedLocation == '/onboarding' || isLoggingIn)) {
            return '/dashboard';
          }
          return null;
        }

        // Not authenticated: login/OTP/M-PIN/registration screens are fine
        // to stay on, everything else forces back to /login.
        if (isLoggingIn) {
          return null;
        }
        return '/login';
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => LoginScreen(
            onOtpSent: () {
              context.go('/otp');
            },
            onOtpPhoneChange: (phone) {
              _currentPhoneForOtp = phone;
            },
            onNeedsMpin: (phone) {
              _currentPhoneForOtp = phone;
              context.go('/mpin-login');
            },
            onBackPress: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/otp',
          name: 'otp',
          builder: (context, state) => OtpScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onVerificationSuccess: () {
              // A vendor who reaches here via "Login with OTP instead"
              // already has an M-PIN and finished onboarding before -
              // verifyOtp() only reports has_mpin for existing vendors, so
              // this flag reflects that correctly either way.
              if (authRepository.hasCompletedOnboardingBefore) {
                partnerAppState.finishOnboarding();
              }
              partnerAppState.setVendorId(authRepository.getCurrentUserId());
              context.go('/dashboard');
            },
            onBackPress: () {
              context.go('/login');
            },
            onNeedsRegistration: (phone) {
              _currentPhoneForOtp = phone;
              context.go('/register-vendor');
            },
          ),
        ),
        GoRoute(
          path: '/mpin-login',
          name: 'mpin-login',
          builder: (context, state) => MpinLoginScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onVerificationSuccess: () {
              partnerAppState.finishOnboarding();
              partnerAppState.setVendorId(authRepository.getCurrentUserId());
              context.go('/dashboard');
            },
            onUseOtpInstead: (phone) {
              _currentPhoneForOtp = phone;
              context.go('/otp');
            },
            onBackPress: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/mpin-setup',
          name: 'mpin-setup',
          builder: (context, state) => MpinSetupScreen(
            onMpinSet: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        GoRoute(
          path: '/register-vendor',
          name: 'register-vendor',
          builder: (context, state) => VendorRegistrationScreen(
            phoneNumber: _currentPhoneForOtp ?? '+91',
            onRegistered: () {
              partnerAppState.setVendorId(authRepository.getCurrentUserId());
              context.go('/dashboard');
            },
          ),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => OnboardingScreen(
            onDone: () {
              context.go('/dashboard');
            },
          ),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => DashboardScreen(
            userRole: 'vendor',
            onLogout: () {
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/verification',
          name: 'verification',
          builder: (context, state) => const VendorVerificationScreen(),
        ),
        GoRoute(
          path: '/bank-verification',
          name: 'bank-verification',
          builder: (context, state) => const BankVerificationScreen(),
        ),
        GoRoute(
          path: '/service-categories',
          name: 'service-categories',
          builder: (context, state) => const ServiceCategoriesScreen(),
        ),
        GoRoute(
          path: '/selfie-verification',
          name: 'selfie-verification',
          builder: (context, state) => const SelfieVerificationScreen(),
        ),
      ],
      initialLocation: '/login',
    );
  }
}
