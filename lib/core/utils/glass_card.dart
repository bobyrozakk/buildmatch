import 'dart:ui';
import 'package:flutter/material.dart';

class IOSGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;

  const IOSGlassCard({super.key, required this.child, this.blur = 25.0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), // Sangat subtle
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}