import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';

class BerandaStatsRow extends StatelessWidget {
  final List<ProjectModel> activeProjects;
  final String ratingStr;

  const BerandaStatsRow({
    super.key,
    required this.activeProjects,
    required this.ratingStr,
  });

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWithIcon(String val, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
                const SizedBox(width: 2),
                Icon(icon, color: Colors.amber, size: 14),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = activeProjects.where((p) => p.status == 'in_progress').length;
    final completedCount = activeProjects.where((p) => p.status == 'completed').length;

    return Row(
      children: [
        _buildStatItem('$activeCount', 'Proyek Aktif'),
        const SizedBox(width: 10),
        _buildStatItem('$completedCount', 'Selesai'),
        const SizedBox(width: 10),
        _buildStatItemWithIcon(ratingStr, 'Rating', Icons.star_rounded),
      ],
    );
  }
}
