import 'package:flutter/material.dart';

class CreateProjectCounterCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int value;
  final Function(int) onChanged;
  final int min;
  final int? max;
  final String? hint;

  const CreateProjectCounterCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final bool atMin = value <= min;
    final bool atMax = max != null && value >= max!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8B2B0F).withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoundBtn(
                Icons.remove,
                atMin ? null : () => onChanged(value - 1),
              ),
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildRoundBtn(
                Icons.add,
                atMax ? null : () => onChanged(value + 1),
                isRed: !atMax,
              ),
            ],
          ),
          if (atMax) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Batas Maksimum',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundBtn(
    IconData icon,
    VoidCallback? onTap, {
    bool isRed = false,
  }) {
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade200
              : (isRed
                  ? const Color(0xFF8B2B0F)
                  : const Color(0xFFF7F4EF)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled
              ? Colors.grey.shade400
              : (isRed ? Colors.white : const Color(0xFF8B2B0F)),
        ),
      ),
    );
  }
}
