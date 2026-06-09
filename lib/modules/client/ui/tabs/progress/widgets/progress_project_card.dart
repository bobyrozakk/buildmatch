import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/providers/project_provider.dart';

class ProgressProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const ProgressProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onEdit,
    required this.onCancel,
  });

  Widget _buildStatusTag(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'open':
        color = Colors.orange;
        label = 'OPEN';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'BERJALAN';
        break;
      case 'completed':
        color = Colors.green;
        label = 'SELESAI';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'DIBATALKAN';
        break;
      case 'draft':
        color = Colors.grey;
        label = 'DRAFT';
        break;
      default:
        color = Colors.grey;
        label = status?.toUpperCase() ?? '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProjectActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'cancel') {
          onCancel();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: 'edit',
            child: FutureBuilder<int>(
              future: Provider.of<ProjectProvider>(context, listen: false)
                  .fetchProjectBidCountAll(project.id ?? ''),
              builder: (ctx, snap) {
                final bidCount = snap.data ?? 0;
                final canEdit = bidCount == 0;
                return Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: canEdit ? AppColors.primary : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Proyek',
                      style: TextStyle(
                        color: canEdit ? Colors.black87 : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    if (!canEdit) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ada bid',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Batalkan Proyek',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAct = project.status == 'open';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
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
                    project.title.isNotEmpty ? project.title : 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusTag(project.status),
                    if (canAct) ...[
                      const SizedBox(width: 4),
                      _buildProjectActionMenu(context),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  project.location ?? 'Lokasi tidak set',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Progres Pembangunan",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "${project.progressPercent}%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: project.progressPercent / 100,
                backgroundColor: AppColors.cardCream,
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
