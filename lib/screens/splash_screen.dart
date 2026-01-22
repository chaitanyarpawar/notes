import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';

/// Lightweight splash screen that matches the native Android splash.
///
/// Design principles:
/// - No artificial delays or timers
/// - No heavy operations (API, DB, Ads, Firebase)
/// - Navigate to home immediately after first frame
/// - UI-only, stateless rendering
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds then navigate
    Future.delayed(const Duration(seconds: 2), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    // Request notification permission in background - don't block
    NotificationService.requestPermissions();

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Static UI matching native splash - no animations
    return Scaffold(
      backgroundColor: const Color(0xFFFF9500), // Orange background
      body: Center(
        child: Image.asset(
          'assets/icon/splash_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
