import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileStatsRow extends StatelessWidget {
  final int activeProjectsCount;
  final int completedProjectsCount;
  final int reviewsCount;

  const ProfileStatsRow({
    super.key,
    required this.activeProjectsCount,
    required this.completedProjectsCount,
    required this.reviewsCount,
  });

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatItem("$activeProjectsCount", "Proyek Aktif"),
        const SizedBox(width: 12),
        _buildStatItem("$completedProjectsCount", "Selesai"),
        const SizedBox(width: 12),
        _buildStatItem("$reviewsCount", "Ulasan"),
      ],
    );
  }
}
