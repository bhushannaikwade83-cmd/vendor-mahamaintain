import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../state/partner_app_state.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  static bool _authenticated = false;

  static GoRouter createRouter(SupabaseAuthRepository authRepository) {
    return GoRouter(
      redirect: (context, state) async {
        final isAuthenticated = authRepository.isAuthenticated();
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp';

        // If on login/OTP screens, stay there
        if (isLoggingIn) {
          return null;
        }

        // If authenticated, go to onboarding (first login) or dashboard
        if (isAuthenticated) {
          if (!partnerAppState.onboardingCompleted &&
              state.matchedLocation != '/onboarding') {
            return '/onboarding';
          }
          if (partnerAppState.onboardingCompleted &&
              state.matchedLocation == '/onboarding') {
            return '/dashboard';
          }
          return null;
        }

        // If not authenticated, go to login
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
              context.go('/dashboard');
            },
            onBackPress: () {
              context.go('/login');
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
      ],
      initialLocation: '/login',
    );
  }
}
