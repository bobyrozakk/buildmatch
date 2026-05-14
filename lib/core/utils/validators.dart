import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Centralized validation and password-strength logic.
class AppValidators {
  AppValidators._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email);

  // ========== Password Strength ==========

  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  static String getStrengthLabel(int score) {
    switch (score) {
      case 1: return 'Lemah';
      case 2: return 'Sedang';
      case 3: return 'Kuat';
      case 4: return 'Sangat Kuat';
      default: return '';
    }
  }

  static Color getStrengthColor(int score) {
    switch (score) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return AppColors.success;
      case 4: return AppColors.successDark;
      default: return Colors.grey.shade300;
    }
  }

  static List<Map<String, dynamic>> getPasswordChecklist(String password) {
    return [
      {'label': 'Minimal 8 karakter', 'valid': password.length >= 8},
      {'label': 'Mengandung huruf besar', 'valid': RegExp(r'[A-Z]').hasMatch(password)},
      {'label': 'Mengandung angka', 'valid': RegExp(r'[0-9]').hasMatch(password)},
      {'label': 'Mengandung karakter khusus', 'valid': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)},
    ];
  }
}
