import 'package:flutter/material.dart';
import 'package:buildmatch/core/utils/formatters.dart';

class BidPriceDiffBanner extends StatelessWidget {
  final double bidPrice;
  final double budget;

  const BidPriceDiffBanner({
    super.key,
    required this.bidPrice,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final diff = bidPrice - budget;
    final isOver = diff > 0;
    final isEqual = diff == 0;

    final color = isOver
        ? Colors.orange.shade700
        : isEqual
            ? Colors.blue.shade700
            : Colors.green.shade700;
    final bg = isOver
        ? Colors.orange.shade50
        : isEqual
            ? Colors.blue.shade50
            : Colors.green.shade50;
    final icon = isOver
        ? Icons.trending_up_rounded
        : isEqual
            ? Icons.trending_flat_rounded
            : Icons.trending_down_rounded;
    final label = isEqual
        ? 'Tepat sesuai budget Anda'
        : isOver
            ? '${AppFormatters.formatRupiah(diff.abs())} di atas budget Anda'
            : '${AppFormatters.formatRupiah(diff.abs())} di bawah budget Anda';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
