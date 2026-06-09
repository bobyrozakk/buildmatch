import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';

class ProfileProjectsList extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  final VoidCallback onRefresh;

  const ProfileProjectsList({
    super.key,
    required this.projects,
    required this.onRefresh,
  });

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Column(
          children: [
            Icon(Icons.assignment_late_outlined, color: Colors.black38, size: 36),
            SizedBox(height: 10),
            Text(
              'Belum ada proyek',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            SizedBox(height: 4),
            Text(
              'Proyek yang Anda buat akan muncul di sini.',
              style: TextStyle(fontSize: 12, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: List.generate(projects.length * 2 - 1, (index) {
          if (index.isOdd) return _divider();
          final itemIndex = index ~/ 2;
          final data = projects[itemIndex];
          final ProjectModel project = data['project'] as ProjectModel;
          final String contractorName = data['contractorName'] as String;

          final Color statusColor;
          final String statusLabel;
          final IconData statusIcon;

          switch (project.status) {
            case 'completed':
              statusColor = Colors.green;
              statusLabel = 'Selesai';
              statusIcon = Icons.home_rounded;
              break;
            case 'in_progress':
              statusColor = const Color(0xFFD85A31);
              statusLabel = 'Berjalan';
              statusIcon = Icons.architecture_rounded;
              break;
            case 'cancelled':
              statusColor = Colors.red;
              statusLabel = 'Dibatalkan';
              statusIcon = Icons.cancel_rounded;
              break;
            default:
              statusColor = Colors.grey.shade600;
              statusLabel = 'Terbuka';
              statusIcon = Icons.business_rounded;
          }

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectDetailScreen(project: project),
                ),
              ).then((_) => onRefresh());
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.backgroundCream, shape: BoxShape.circle),
              child: Icon(statusIcon, color: AppColors.primary, size: 24),
            ),
            title: Text(
              project.title.isNotEmpty ? project.title : 'Tanpa Judul',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              contractorName,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
          );
        }),
      ),
    );
  }
}
