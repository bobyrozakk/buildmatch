import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProgressEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const ProgressEmptyState({
    super.key,
    this.title = 'Belum Ada Aktivitas Proyek',
    this.description = 'Ajukan penawaran ke proyek klien agar progress pekerjaan muncul di sini.',
    this.icon = Icons.timeline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
