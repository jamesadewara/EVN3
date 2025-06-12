import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(AppConfig.splashScreenDuration);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Icon(
              Icons.inventory_2,
              size: 100,
              color: Colors.white,
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                ),

            const SizedBox(height: 24),

            // App Name
            Text(
              'EVN3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 500),
                ),

            const SizedBox(height: 16),

            // App Description
            Text(
              'Inventory Management System',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 600))
                .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: const Duration(milliseconds: 500),
                ),

            const SizedBox(height: 48),

            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 900))
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                ),
          ],
        ),
      ),
    );
  }
} 