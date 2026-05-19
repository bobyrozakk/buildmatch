import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

class KontraktorBidDetailScreen extends StatelessWidget {
  final BidModel bid;

  const KontraktorBidDetailScreen({
    super.key,
    required this.bid,
  });

  @override
  Widget build(BuildContext context) {
    final project = bid.project;

    final isAccepted = bid.status == 'accepted';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Detail Penawaran',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// HERO STATUS CARD
            IOSGlassCard(
              blur: 15,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _statusChip(bid.status),

                    const SizedBox(height: 16),

                    Text(
                      project?.title ?? 'Proyek',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      AppFormatters.formatRupiah(bid.price),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project?.location ?? '-',
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// DETAIL INFO
            _sectionTitle('Informasi Penawaran'),

            const SizedBox(height: 14),

            IOSGlassCard(
              blur: 12,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [

                    _infoTile(
                      Icons.account_balance_wallet_outlined,
                      'Budget Klien',
                      AppFormatters.formatRupiah(
                        project?.budget ?? 0,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _infoTile(
                      Icons.payments_outlined,
                      'Penawaran Anda',
                      AppFormatters.formatRupiah(
                        bid.price,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _infoTile(
                      Icons.calendar_month_outlined,
                      'Status',
                      bid.status.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// TIMELINE
            _sectionTitle('Progress Penawaran'),

            const SizedBox(height: 14),

            IOSGlassCard(
              blur: 12,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [

                    _timelineItem(
                      true,
                      'Penawaran Terkirim',
                    ),

                    _timelineItem(
                      true,
                      'Sedang Direview Klien',
                    ),

                    _timelineItem(
                      isAccepted,
                      'Penawaran Diterima',
                    ),

                    _timelineItem(
                      isAccepted &&
                          (project?.progressPercent ?? 0) > 0,
                      'Pembangunan Dimulai',
                    ),
                  ],
                ),
              ),
            ),

            if (bid.message != null &&
                bid.message!.isNotEmpty) ...[

              const SizedBox(height: 22),

              _sectionTitle('Catatan Anda'),

              const SizedBox(height: 14),

              IOSGlassCard(
                blur: 12,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    bid.message!,
                    style: const TextStyle(
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],

            if (isAccepted) ...[

              const SizedBox(height: 22),

              _sectionTitle('Progress Pembangunan'),

              const SizedBox(height: 14),

              IOSGlassCard(
                blur: 12,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progress Saat Ini',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${project?.progressPercent ?? 0}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value:
                              (project?.progressPercent ?? 0) / 100,
                          minHeight: 10,
                          backgroundColor:
                              AppColors.cardCream,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardCream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineItem(
    bool active,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [

          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 14,
              color: active
                  ? Colors.white
                  : Colors.grey,
            ),
          ),

          const SizedBox(width: 14),

          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.black87
                  : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {

    Color color;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'DITERIMA';
        break;

      case 'rejected':
        color = Colors.red;
        text = 'DITOLAK';
        break;

      default:
        color = Colors.orange;
        text = 'MENUNGGU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}