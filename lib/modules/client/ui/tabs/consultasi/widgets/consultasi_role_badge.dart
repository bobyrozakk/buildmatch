import 'package:flutter/material.dart';

class ConsultasiRoleBadge extends StatelessWidget {
  final String? role;

  const ConsultasiRoleBadge({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == null) return const SizedBox.shrink();
    final isContractor = role == 'vendor' || role == 'kontraktor';
    final isArchitect = role == 'architect' || role == 'arsitek';
    if (!isContractor && !isArchitect) return const SizedBox.shrink();

    final String label = isContractor ? 'Kontraktor' : 'Arsitek';
    final Color bgColor = isContractor 
        ? const Color(0xFFFDF2E9) // soft orange/brown
        : const Color(0xFFEBF5FB); // soft blue
    final Color textColor = isContractor 
        ? const Color(0xFFD35400) // dark orange
        : const Color(0xFF2980B9); // dark blue
    final Color borderColor = isContractor
        ? const Color(0xFFF5CBA7)
        : const Color(0xFFAED6F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
