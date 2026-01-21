import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400), // Faster animation
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Request notification permission explicitly
    await NotificationService.requestPermissions();

    // Short delay for splash visibility
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF9500), // Orange background
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PebbleNotes Logo - full coverage
                    Image.asset(
                      'assets/icon/icon.png',
                      width: MediaQuery.of(context).size.width * 0.55,
                      height: MediaQuery.of(context).size.width * 0.55,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 40),

                    // Tagline with elegant Parisienne script font
                    Text(
                      'Capture Your Thoughts',
                      style: GoogleFonts.parisienne(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
