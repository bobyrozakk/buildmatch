import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';

class ProgressGroupedBidCard extends StatelessWidget {
  final List<BidModel> projectBids;
  final ProjectModel? project;
  final VoidCallback onRefresh;

  const ProgressGroupedBidCard({
    super.key,
    required this.projectBids,
    required this.project,
    required this.onRefresh,
  });

  Widget _buildBidPreviewRow(BuildContext context, BidModel bid, int index, ProjectModel? navProject) {
    final vendorName = bid.vendorName ?? 'Kontraktor';
    final initial = vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'K';

    return InkWell(
      onTap: () {
        if (navProject != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: navProject),
            ),
          ).then((_) => onRefresh());
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: index == 0
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: index == 0 ? AppColors.primary : Colors.black45,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                vendorName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              AppFormatters.formatRupiah(bid.price),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectTitle = project?.title ?? projectBids.first.project?.title ?? 'Proyek';
    final bool isAcceptedOrInProgress = project?.status == 'in_progress' ||
        projectBids.any((b) => b.status == 'accepted' || b.project?.status == 'in_progress');

    final List<BidModel> previewBids;
    if (isAcceptedOrInProgress) {
      previewBids = projectBids.where((b) => b.status == 'accepted').toList();
    } else {
      previewBids = projectBids.take(3).toList();
    }

    final remaining = isAcceptedOrInProgress ? 0 : (projectBids.length - previewBids.length);
    final ProjectModel? navProject = project;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_outlined, size: 18, color: Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isAcceptedOrInProgress
                            ? 'Penawaran Diterima'
                            : '${projectBids.length} kontraktor menawar',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAcceptedOrInProgress ? 'Diterima' : '${projectBids.length} bid',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          ...previewBids.asMap().entries.map((entry) {
            final index = entry.key;
            final bid = entry.value;
            return _buildBidPreviewRow(context, bid, index, navProject);
          }),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                '+$remaining kontraktor lainnya',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (navProject != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: navProject),
                      ),
                    ).then((_) => onRefresh());
                  }
                },
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Lihat Detail Seluruhnya',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
