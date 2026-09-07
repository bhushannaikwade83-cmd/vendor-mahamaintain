import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/deep_link_service.dart';
import 'config/supabase_config.dart';
import 'repositories/auth_repository.dart';
import 'screens/splash_screen.dart';
import 'state/partner_app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MahaMaintainVendorApp(),
    ),
  );
}

final authRepositoryProvider = Provider((ref) => SupabaseAuthRepository());

class MahaMaintainVendorApp extends ConsumerStatefulWidget {
  const MahaMaintainVendorApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MahaMaintainVendorApp> createState() => _MahaMaintainVendorAppState();
}

class _MahaMaintainVendorAppState extends ConsumerState<MahaMaintainVendorApp> {
  bool _showSplash = true;
  bool _sessionRestored = false;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Restore any previously logged-in session (and onboarding progress)
    // from disk before the router's first redirect decision runs - a
    // vendor should only ever be signed out by an explicit Logout tap, not
    // by closing the app.
    final authRepository = ref.read(authRepositoryProvider);
    await Future.wait([
      authRepository.restoreSession(),
      partnerAppState.restore(),
    ]);
    partnerAppState.setVendorId(authRepository.getCurrentUserId());

    _router = AppRouter.createRouter(authRepository);
    DeepLinkService.init(_router);
    if (mounted) setState(() => _sessionRestored = true);

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash || !_sessionRestored) {
      return MaterialApp(
        title: 'Maha Maintain Pro Partner',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onSplashComplete: () {
            if (mounted) {
              setState(() => _showSplash = false);
            }
          },
        ),
      );
    }

    return MaterialApp.router(
      title: 'Maha Maintain Pro Partner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
