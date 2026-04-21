import 'dart:ui';
import 'package:flutter/material.dart';

class NeonGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color neonColor;

  const NeonGlassCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(20.0),
    this.neonColor = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // Sangat transparan
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: neonColor.withOpacity(0.4), 
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: neonColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}