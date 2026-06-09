import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/modules/client/ui/screens/architect_offer_detail/architect_offer_detail_screen.dart';

class ProgressArchitectBidCard extends StatelessWidget {
  final BidModel bid;
  final VoidCallback onRefresh;

  const ProgressArchitectBidCard({
    super.key,
    required this.bid,
    required this.onRefresh,
  });

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
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

  @override
  Widget build(BuildContext context) {
    // Parse pesan arsitek (berisi title, description, revisions, duration_days)
    String offerTitle = 'Penawaran Desain';
    String offerDescription = '';
    int revisions = 0;
    int durationDays = 0;

    if (bid.message != null && bid.message!.startsWith('{')) {
      try {
        final data = jsonDecode(bid.message!);
        offerTitle = data['title'] ?? offerTitle;
        offerDescription = data['description'] ?? '';
        revisions = data['revisions'] ?? 0;
        durationDays = data['duration_days'] ?? 0;
      } catch (_) {}
    }

    final architectName = bid.vendorName ?? 'Arsitek';
    final initial = architectName.isNotEmpty ? architectName[0].toUpperCase() : 'A';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (bid.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = 'Diterima';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Ditolak';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Dibatalkan';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    void handleNavigation() {
      if (bid.id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArchitectOfferDetailScreen(
              bidId: bid.id!,
              title: offerTitle,
              price: bid.price,
              description: offerDescription,
              revisions: revisions,
              durationDays: durationDays,
              architectName: architectName,
            ),
          ),
        ).then((_) => onRefresh());
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: handleNavigation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar arsitek
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.purple.withValues(alpha: 0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.architecture_rounded,
                                size: 13, color: Colors.purple),
                            const SizedBox(width: 4),
                            const Text(
                              'Arsitek',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          architectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Judul penawaran
              Text(
                offerTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _miniChip(
                    Icons.payments_outlined,
                    AppFormatters.formatRupiah(bid.price),
                    Colors.purple,
                  ),
                  if (durationDays > 0)
                    _miniChip(
                      Icons.schedule_rounded,
                      '$durationDays hari',
                      Colors.blue,
                    ),
                  if (revisions > 0)
                    _miniChip(
                      Icons.loop_rounded,
                      '$revisions revisi',
                      Colors.teal,
                    ),
                ],
              ),

              // Tombol lihat detail
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: handleNavigation,
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: Colors.purple,
                  ),
                  label: const Text(
                    'Lihat Detail Penawaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(
                      color: Colors.purple.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.purple.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
