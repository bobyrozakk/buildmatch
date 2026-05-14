import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Primary Brand Colors ===
  static const Color primary = Color(0xFF8B2B0F);
  static const Color primaryDark = Color(0xFFB53D1B);
  static const Color primaryLight = Color(0xFFD85A31);
  static const Color accent = Color(0xFFC95E36);

  // === Background Colors ===
  static const Color backgroundCream = Color(0xFFF7F4EF);
  static const Color backgroundOnboarding = Color(0xFFF2E9DF);
  static const Color cardCream = Color(0xFFEFEBE4);
  static const Color cardCreamLight = Color(0xFFF3EBE1);
  static const Color cardCreamMedium = Color(0xFFF0E5D3);
  static const Color checklistBg = Color(0xFFFAF7F3);

  // === Gradient Colors ===
  static const Color gradientBlue = Color(0xFFF3F8FF);
  static const Color gradientPink = Color(0xFFFFF0F5);
  static const Color warmSand = Color(0xFFE8CDB6);

  // === Semantic Colors ===
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF2E7D32);

  // === Common Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pastelGradient = LinearGradient(
    colors: [gradientBlue, gradientPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
