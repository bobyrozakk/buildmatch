import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          const Spacer(flex: 3),

          // Branded Svg Logo
          SvgPicture.asset(
            'assets/images/buildmatch_logo.svg',
            width: 100,
            height: 100,
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
    );
  }
}
