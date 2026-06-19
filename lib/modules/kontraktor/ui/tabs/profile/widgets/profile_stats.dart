import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileStats extends StatelessWidget {
  final int portfolioCount;
  final int certificationCount;
  final String rating;
  final String reviewsCount;

  const ProfileStats({
    super.key,
    required this.portfolioCount,
    required this.certificationCount,
    required this.rating,
    required this.reviewsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem('TOTAL PORTOFOLIO', '$portfolioCount')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem('SERTIFIKASI MITRA', '$certificationCount')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatItem('RATING MITRA', '$rating / 5.0')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem('TOTAL ULASAN', reviewsCount)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
