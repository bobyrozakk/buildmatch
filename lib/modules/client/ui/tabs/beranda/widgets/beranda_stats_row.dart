import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class BerandaStatsRow extends StatelessWidget {
  final int activeCount;
  final int openCount;
  final int bidsCount;

  const BerandaStatsRow({
    super.key,
    required this.activeCount,
    required this.openCount,
    required this.bidsCount,
  });

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatItem('$activeCount', 'Proyek Aktif'),
        const SizedBox(width: 10),
        _buildStatItem('$openCount', 'Open\nTender'),
        const SizedBox(width: 10),
        _buildStatItem('$bidsCount', 'Penawaran\nMasuk'),
      ],
    );
  }
}
