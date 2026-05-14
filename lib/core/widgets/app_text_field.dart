import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Reusable text field widget used across all screens.
/// Replaces _buildFigmaTextField and _buildSmoothTextField duplicates.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? suffixText;
  final bool borderless;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleObscure,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixText,
    this.borderless = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary.withOpacity(0.8), size: 20)
            : null,
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderless ? 16 : 12),
          borderSide: borderless ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderless ? 16 : 12),
          borderSide: borderless ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderless ? 16 : 12),
          borderSide: borderless ? BorderSide.none : const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
