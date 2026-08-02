import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/supabase_config.dart';
import 'repositories/auth_repository.dart';
import 'screens/splash_screen.dart';

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

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        title: 'MahaMaintain Pro - Channel Partners',
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

    final authRepository = ref.watch(authRepositoryProvider);
    final router = AppRouter.createRouter(authRepository);

    return MaterialApp.router(
      title: 'MahaMaintain Pro - Channel Partners',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
