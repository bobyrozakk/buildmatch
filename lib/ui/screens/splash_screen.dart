import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, a3, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9B3517),
              Color(0xFF7A220A),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Hammer Icon
              Icon(
                Icons.hardware_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.95),
              ),
              const SizedBox(height: 20),

              // App Name
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Build',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Match',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Jasa Konstruksi Terpercaya',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 0.3,
                ),
              ),

              const Spacer(flex: 4),

              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Text(
                  'POLITEKNIK NEGERI MALANG · 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
