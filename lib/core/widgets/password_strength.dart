import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../constants/colors.dart';

/// Shared password strength indicator bar.
/// Replaces duplicated _buildPasswordStrengthBar in register & create_new_password screens.
class PasswordStrengthBar extends StatelessWidget {
  final int strength;

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final label = AppValidators.getStrengthLabel(strength);
    final color = AppValidators.getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Kekuatan Password",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < strength ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Shared password requirements checklist.
/// Replaces duplicated _buildPasswordChecklist in register & create_new_password screens.
class PasswordChecklist extends StatelessWidget {
  final String password;

  const PasswordChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = AppValidators.getPasswordChecklist(password);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.checklistBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Syarat Password",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...checks.map((check) {
            final isValid = check['valid'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: isValid ? AppColors.success : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    check['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? AppColors.success : Colors.black45,
                      fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
