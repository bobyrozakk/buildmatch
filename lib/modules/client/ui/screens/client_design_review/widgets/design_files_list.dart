import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class DesignFilesList extends StatelessWidget {
  final List<Map<String, String>> files;
  final ValueChanged<String> onOpenFile;

  const DesignFilesList({
    super.key,
    required this.files,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5DCD3)),
        ),
        child: const Center(
          child: Text('Tidak ada berkas yang disertakan.', style: TextStyle(color: Colors.black45, fontSize: 13)),
        ),
      );
    }

    return Column(
      children: files.map((file) {
        final name = file['name'] ?? 'File';
        final type = file['type'] ?? 'file';
        final url = file['url'] ?? '';
        
        IconData icon = Icons.insert_drive_file_outlined;
        Color color = Colors.grey.shade700;

        if (type == 'image') {
          icon = Icons.image_outlined;
          color = Colors.blue.shade700;
        } else if (type == 'pdf') {
          icon = Icons.picture_as_pdf_outlined;
          color = Colors.red.shade700;
        } else if (type == 'autocad') {
          icon = Icons.architecture_rounded;
          color = Colors.teal.shade700;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DCD3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text('Buka', style: TextStyle(fontSize: 12)),
                onPressed: url.isNotEmpty ? () => onOpenFile(url) : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
