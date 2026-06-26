import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/core/theme.dart';
import 'package:sharoni/features/auth/presentation/login_page.dart';
import 'package:sharoni/features/auth/presentation/auth_controller.dart';
import 'package:sharoni/features/home/presentation/home_scaffold.dart';
import 'package:sharoni/features/profile/presentation/profile_controller.dart';
import 'package:sharoni/features/auth/presentation/profile_setup_page.dart';

import 'package:sharoni/core/services/notification_service.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  // Initialize Notifications with global key
  await NotificationService().init(key: messengerKey);

  await Supabase.initialize(
    url: 'https://sfvflstzralywaqkjuje.supabase.co',
    anonKey: 'sb_publishable_y6xrbvvZJjH-slDOlw5-Gw_kRtqTQRA',
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Medicare',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: messengerKey,
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginPage();
          
          // Reactively watch profile to decide if setup is needed
          return ref.watch(profileControllerProvider).when(
            data: (profile) {
              if (profile == null) {
                return const ProfileSetupPage();
              }
              return const HomeScaffold();
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, st) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Profile Error: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const _SplashScreen(),
        error: (e, st) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Something went wrong on startup.'),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown while [AuthController] is in its loading state (waiting for
/// Supabase to restore the persisted session). Prevents a flash of the
/// login screen before the token is confirmed.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Medicare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
