import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../features/home/presentation/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _taxiSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Zoom Out Animation:
    // Starts at 3.0 (Zoomed In on Center - presumably "EV")
    // Ends at 1.0 (Full Logo visible)
    _scaleAnimation = Tween<double>(begin: 4.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    // Taxi Movement:
    // Moves from bottom (off-screen) towards the center/logo
    _taxiSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0), // Start below screen
      end: const Offset(0, 0.6),   // End slightly below center (under logo)
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(seconds: 1), () async {
          if (mounted) {
            final biometricService = BiometricService();
            final enabled = await biometricService.isBiometricEnabled();
            
            if (enabled) {
              final authenticated = await biometricService.authenticate();
              if (authenticated && mounted) {
                 Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (context) => const HomePage()), // Go to Home directly if auth success
                 );
                 return;
              }
            }

            if (mounted) {
                Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                );
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Logo Animation
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Image.asset(
                  'assets/images/logo_main.png',
                  key: const ValueKey('logo'),
                  width: MediaQuery.of(context).size.width * 0.9,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Taxi Animation
          // Positioned relative to the whole screen size using FractionalTranslation?
          // SlideTransition uses offset proportional to child size.
          // Let's use SlideTransition wrapped in Align or Center.
          Center(
            child: SlideTransition(
              position: _taxiSlideAnimation,
              child: Transform.translate(
                offset: const Offset(0, 50), // Fine tune base position
                child: RotatedBox(
                  quarterTurns: 3, 
                  child: Image.asset(
                    'assets/images/taxi.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}