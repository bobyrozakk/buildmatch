import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ConsultasiInboxEmpty extends StatelessWidget {
  final VoidCallback? onFindMitra;

  const ConsultasiInboxEmpty({
    super.key,
    this.onFindMitra,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada percakapan',
            style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai konsultasi dengan arsitek\natau kontraktor di tab Mitra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black38, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onFindMitra,
            icon: const Icon(Icons.groups_outlined, size: 16),
            label: const Text('Cari Mitra'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
