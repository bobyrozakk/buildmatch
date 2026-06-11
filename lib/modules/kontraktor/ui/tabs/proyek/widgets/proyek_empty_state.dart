import 'package:flutter/material.dart';

class ProyekEmptyState extends StatelessWidget {
  const ProyekEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Tidak ada proyek ditemukan', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Coba ubah filter atau kata kunci pencarian', style: TextStyle(fontSize: 12, color: Colors.black38)),
        ],
      ),
    );
  }
}
