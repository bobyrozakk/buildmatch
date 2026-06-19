import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';

class BerandaMyProjects extends StatelessWidget {
  final List<ProjectModel> projects;
  final VoidCallback onMulaiProyek;
  final VoidCallback? onRefresh;

  const BerandaMyProjects({
    super.key,
    required this.projects,
    required this.onMulaiProyek,
    this.onRefresh,
  });

  void _openProjectDetail(BuildContext context, ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)),
    ).then((_) => onRefresh?.call());
  }

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 44,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada proyek',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Buat proyek pertamamu untuk mulai\nmendapatkan penawaran kontraktor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onMulaiProyek,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Buat Proyek',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final list = projects.take(3).toList();
    return Column(
      children: list.map((p) {
        final isActive = p.status == 'in_progress';
        final progress = (p.progressPercent / 100).clamp(0.0, 1.0);

        final String statusLabel;
        final Color statusColor;
        if (p.status == 'in_progress') {
          statusLabel = 'BERJALAN';
          statusColor = Colors.blue.shade700;
        } else if (p.status == 'open') {
          statusLabel = 'OPEN TENDER';
          statusColor = Colors.orange.shade800;
        } else {
          statusLabel = (p.status ?? 'N/A').toUpperCase();
          statusColor = Colors.grey.shade700;
        }

        return GestureDetector(
          onTap: () => _openProjectDetail(context, p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.location ?? 'Lokasi tidak diketahui',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.formatRupiah(p.budget),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progres',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        '${p.progressPercent}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
