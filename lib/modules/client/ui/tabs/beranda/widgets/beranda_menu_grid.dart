import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class BerandaMenuGrid extends StatelessWidget {
  final VoidCallback onMulaiProyek;
  final VoidCallback onCariKontraktor;
  final VoidCallback onCariArsitek;
  final VoidCallback onLihatProgress;

  const BerandaMenuGrid({
    super.key,
    required this.onMulaiProyek,
    required this.onCariKontraktor,
    required this.onCariArsitek,
    required this.onLihatProgress,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _MenuItem(
        Icons.add_circle_outline_rounded,
        'Buat Proyek',
        onMulaiProyek,
      ),
      _MenuItem(
        Icons.engineering_rounded,
        'Cari Kontraktor',
        onCariKontraktor,
      ),
      _MenuItem(
        Icons.architecture_outlined,
        'Cari Arsitek',
        onCariArsitek,
      ),
      _MenuItem(
        Icons.timeline_rounded,
        'Lihat Progress',
        onLihatProgress,
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: menuItems.map((item) {
        return GestureDetector(
          onTap: item.onTap,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  _MenuItem(this.icon, this.label, this.onTap);
}
