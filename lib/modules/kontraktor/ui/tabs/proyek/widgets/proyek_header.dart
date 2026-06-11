import 'package:flutter/material.dart';

class ProyekHeader extends StatelessWidget {
  final bool isBidFilter;
  final String selectedFilter;
  final int totalCount;

  const ProyekHeader({
    super.key,
    required this.isBidFilter,
    required this.selectedFilter,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final title = isBidFilter ? selectedFilter : 'Proyek Tersedia';
    final subtitle = isBidFilter ? '$totalCount penawaran' : '$totalCount proyek aktif';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
