import 'package:flutter/material.dart';

class DesignRevisionsInfoPanel extends StatelessWidget {
  final int maxRevisions;
  final int remainingRevisions;

  const DesignRevisionsInfoPanel({
    super.key,
    required this.maxRevisions,
    required this.remainingRevisions,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = remainingRevisions;
    final max = maxRevisions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: remaining > 0 
            ? Colors.teal.withValues(alpha: 0.06) 
            : Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remaining > 0 
              ? Colors.teal.withValues(alpha: 0.15) 
              : Colors.red.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            remaining > 0 ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
            color: remaining > 0 ? Colors.teal : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remaining > 0 ? 'Kuota Revisi Tersedia' : 'Batas Revisi Habis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: remaining > 0 ? Colors.teal : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remaining > 0
                      ? 'Kamu dapat mengajukan revisi sebanyak $remaining kali lagi dari total $max revisi.'
                      : 'Batas revisi sebanyak $max kali telah digunakan semua. Silakan setujui draf final ini.',
                  style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
