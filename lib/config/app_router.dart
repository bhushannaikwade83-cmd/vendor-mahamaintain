import 'package:go_router/go_router.dart';
import '../repositories/auth_repository.dart';
import '../screens/role_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/dashboard_screen.dart';

class AppRouter {
  static String? _currentPhoneForOtp;
  static String? _selectedRole;
  static bool _roleSelected = false;

  static GoRouter createRouter(SupabaseAuthRepository authRepository) {
    return GoRouter(
      redirect: (context, state) async {
        final isAuthenticated = authRepository.isAuthenticated();
        final isSelectingRole = state.matchedLocation == '/' || state.matchedLocation == '/role-selection';
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/otp';

        // If on login/OTP screens, stay there
        if (isLoggingIn) {
          return null;
        }

        // If authenticated and role selected, go to dashboard
        if (isAuthenticated && _roleSelected && _selectedRole != null) {
          return '/dashboard';
        }

        // If role not selected, go to role selection
        if (!_roleSelected || _selectedRole == null) {
          return '/';
        }

        // If role selected but not authenticated, go to login
        if (_roleSelected && !isAuthenticated) {
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => RoleSelectionScreen(
            onRoleSelected: (role) {
              _selectedRole = role;
              _roleSelected = true;
              context.go('/login');
            },
          ),
        ),
        GoRoute(
          path: '/role-selection',
          name: 'roleSelection',
          builder: (context, state) => RoleSelectionScreen(
            onRoleSelected: (role) {
              _selectedRole = role;
              _roleSelected = true;
              context.go('/login');
            },
          ),
        ),
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
              _roleSelected = false;
              context.go('/role-selection');
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
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => DashboardScreen(
            userRole: _selectedRole ?? 'individual',
            onLogout: () {
              _roleSelected = false;
              _selectedRole = null;
              context.go('/role-selection');
            },
          ),
        ),
      ],
      initialLocation: '/',
    );
  }
}
