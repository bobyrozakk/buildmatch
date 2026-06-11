import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';

class BerandaProyekBerjalan extends StatelessWidget {
  final List<ProjectModel> activeProjects;
  final ValueChanged<ProjectModel> onProjectTap;

  const BerandaProyekBerjalan({
    super.key,
    required this.activeProjects,
    required this.onProjectTap,
  });

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final list = activeProjects.where((p) => p.status == 'in_progress').take(3).toList();
    if (list.isEmpty) {
      return _buildEmptyCard('Belum ada proyek berjalan');
    }
    return Column(
      children: list.map((p) {
        final progress = (p.progressPercent / 100.0).clamp(0.0, 1.0);
        return GestureDetector(
          onTap: () => onProjectTap(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      p.imageUrls[0], 
                      height: 120, 
                      width: double.infinity, 
                      fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => Container(
                        height: 120, 
                        color: Colors.grey.shade200, 
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)
                      )
                    ),
                  )
                else
                  Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _formatDate(p.createdAt),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 13, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(p.clientName ?? 'Klien', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progres', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('${p.progressPercent}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
