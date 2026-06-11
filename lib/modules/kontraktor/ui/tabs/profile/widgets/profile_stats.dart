import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileStats extends StatelessWidget {
  final int portfolioCount;
  final List<Map<String, dynamic>> reviews;

  const ProfileStats({
    super.key,
    required this.portfolioCount,
    required this.reviews,
  });

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num? ?? 0.0));
      avgRating = total / reviews.length;
    }
    final ratingStr = reviews.isEmpty ? '0.0' : avgRating.toStringAsFixed(1);

    return Row(
      children: [
        _statBox(
          portfolioCount.toString(),
          'Portofolio',
        ),
        const SizedBox(width: 12),
        _statBox(ratingStr, 'Rating'),
        const SizedBox(width: 12),
        _statBox('Aktif', 'Status'),
      ],
    );
  }
}
