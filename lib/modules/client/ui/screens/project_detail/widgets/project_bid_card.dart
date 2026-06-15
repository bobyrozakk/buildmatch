import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import '../../client_payment_terms/client_payment_terms_screen.dart';
import '../project_detail_screen.dart';

class ProjectBidCard extends StatelessWidget {
  final BidModel bid;
  final int rank;
  final BidSortOption sortOption;
  final ProjectModel project;
  final VoidCallback onOpenBidDetail;

  const ProjectBidCard({
    super.key,
    required this.bid,
    required this.rank,
    required this.sortOption,
    required this.project,
    required this.onOpenBidDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = bid.status == 'accepted';
    final isRejected = bid.status == 'rejected';

    Color statusColor = Colors.orange;
    String statusLabel = 'Menunggu';
    if (isAccepted) {
      statusColor = Colors.green;
      statusLabel = 'Diterima';
    } else if (isRejected) {
      statusColor = Colors.red;
      statusLabel = 'Ditolak';
    }

    final priceColor = bid.price <= project.budget
        ? Colors.green.shade700
        : bid.price <= project.budget * 1.1
        ? Colors.black87
        : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAccepted
            ? Border.all(color: Colors.green.shade200, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge nomor urut pas di-sort
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: rank == 1 && sortOption != BidSortOption.newest
                      ? AppColors.primary
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank == 1 && sortOption != BidSortOption.newest
                          ? Colors.white
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: bid.vendorAvatarUrl != null && bid.vendorAvatarUrl!.isNotEmpty
                    ? NetworkImage(bid.vendorAvatarUrl!)
                    : null,
                child: bid.vendorAvatarUrl == null || bid.vendorAvatarUrl!.isEmpty
                    ? Text(
                        (bid.vendorName?.isNotEmpty == true)
                            ? bid.vendorName![0].toUpperCase()
                            : 'K',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bid.vendorName ?? 'Kontraktor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatRupiah(bid.price),
                      style: TextStyle(
                        color: priceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Penggabungan Chip Spek Baru (Experience + Rating)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (bid.estimationMonths != null)
                _miniInfoChip(
                  Icons.schedule_rounded,
                  '${bid.estimationMonths} bln',
                  Colors.blue,
                ),
              if (bid.vendorExperienceYears != null)
                _miniInfoChip(
                  Icons.workspace_premium_rounded,
                  '${bid.vendorExperienceYears} thn kerja',
                  Colors.purple,
                ),
              if (bid.vendorRating != null)
                _miniInfoChip(
                  Icons.star_rounded,
                  bid.vendorRating!.toStringAsFixed(1),
                  Colors.amber.shade700,
                ),
              if (bid.rabUrl != null && bid.rabUrl!.isNotEmpty)
                _miniInfoChip(Icons.description_rounded, 'RAB', Colors.green),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenBidDetail,
              icon: const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Tombol lihat termin (hanya jika accepted)
          if (isAccepted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientPaymentTermsScreen(
                        projectId: project.id ?? '',
                        dealPrice: bid.price,
                        projectTitle: project.title,
                        contractorName: bid.vendorName ?? 'Kontraktor',
                        contractorId: bid.vendorId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.payments_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Lihat Termin Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
