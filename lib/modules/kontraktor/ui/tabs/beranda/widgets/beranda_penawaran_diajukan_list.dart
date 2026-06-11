import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/project_model.dart';

class BerandaPenawaranDiajukanList extends StatelessWidget {
  final List<BidModel> bids;
  final ValueChanged<ProjectModel> onProjectTap;

  const BerandaPenawaranDiajukanList({
    super.key,
    required this.bids,
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

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color ?? Colors.black54),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color ?? Colors.black54, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
    return _formatDate(date);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (bids.isEmpty) {
      return _buildEmptyCard('Belum ada penawaran diajukan');
    }
    final list = bids.take(5).toList();
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          final p = b.project;
          return GestureDetector(
            onTap: p == null ? null : () => onProjectTap(p),
            child: Container(
              width: 220,
              margin: EdgeInsets.only(right: i < list.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p?.imageUrls.isNotEmpty == true)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p!.imageUrls[0], 
                        height: 100, 
                        width: double.infinity, 
                        fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => Container(
                          height: 100, 
                          color: Colors.grey.shade200, 
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)
                        )
                      ),
                    )
                  else
                    Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final isRejected = b.status == 'rejected' || (b.status == 'pending' && b.createdAt != null && DateTime.now().difference(b.createdAt!).inDays > 7);
                    final statusLabel = isRejected ? 'Diabaikan' : 'Menunggu';
                    final statusColor = isRejected ? Colors.red : Colors.orange;
                    final statusIcon = isRejected ? Icons.cancel_outlined : Icons.access_time_rounded;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    p?.title ?? 'Proyek tidak tersedia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _infoRow(Icons.person_outline, p?.clientName ?? 'Klien'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.location_on_outlined, p?.location ?? '-'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.monetization_on_outlined, AppFormatters.formatRupiah(b.price), color: AppColors.primary, bold: true),
                  const Spacer(),
                  Text(_timeAgo(b.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
