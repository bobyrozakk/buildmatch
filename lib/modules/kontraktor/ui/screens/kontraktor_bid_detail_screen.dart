import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'kontraktor_payment_terms_screen.dart';

class KontraktorBidDetailScreen extends StatelessWidget {
  final BidModel bid;
  const KontraktorBidDetailScreen({
    super.key,
    required this.bid,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak dapat membuka file RAB.')),
      );
    }
  }

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
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Hero Status Card ──
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
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppFormatters.formatRupiah(bid.price),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project?.location ?? '-',
                            style: const TextStyle(
                                color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Informasi Penawaran ──
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
                          project?.budget ?? 0),
                    ),
                    const SizedBox(height: 16),
                    _infoTile(
                      Icons.payments_outlined,
                      'Penawaran Anda',
                      AppFormatters.formatRupiah(bid.price),
                    ),
                    const SizedBox(height: 16),
                    _infoTile(
                      Icons.calendar_month_outlined,
                      'Status',
                      bid.status.toUpperCase(),
                    ),
                    // ── Estimasi bulan ──
                    if (bid.estimationMonths != null) ...[
                      const SizedBox(height: 16),
                      _infoTile(
                        Icons.schedule_rounded,
                        'Estimasi Pengerjaan',
                        '${bid.estimationMonths} Bulan',
                      ),
                    ],
                    // ── Tombol buka RAB ──
                    if (bid.rabUrl != null &&
                        bid.rabUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _rabTile(context, bid.rabUrl!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Timeline Progress Penawaran ──
            _sectionTitle('Progress Penawaran'),
            const SizedBox(height: 14),
            IOSGlassCard(
              blur: 12,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _timelineItem(true, 'Penawaran Terkirim'),
                    _timelineItem(
                        true, 'Sedang Direview Klien'),
                    _timelineItem(
                        isAccepted, 'Penawaran Diterima'),
                    _timelineItem(
                      isAccepted &&
                          (project?.progressPercent ?? 0) > 0,
                      'Pembangunan Dimulai',
                    ),
                  ],
                ),
              ),
            ),

            // ── Catatan Kontraktor ──
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
                        height: 1.5, color: Colors.black87),
                  ),
                ),
              ),
            ],

            // ── Progress Pembangunan (jika sudah accepted) ──
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
                          const Text('Progress Saat Ini',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${project?.progressPercent ?? 0}%',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value:
                              (project?.progressPercent ?? 0) /
                                  100,
                          minHeight: 10,
                          backgroundColor: AppColors.cardCream,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Tombol Lanjut Pembayaran (hanya jika accepted) ──
            if (isAccepted) ...[
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.celebration_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Penawaran Diterima!',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Atur termin pembayaran untuk proyek ini. Tentukan berapa tahap dan persentase tiap tahap.',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KontraktorPaymentTermsScreen(
                                projectId: bid.projectId, // FIX: gunakan bid.projectId yg selalu ada
                                bidId: bid.id ?? '',
                                dealPrice: bid.price,
                                projectTitle:
                                    project?.title ?? 'Proyek',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(
                            Icons.payments_rounded,
                            color: AppColors.primary,
                            size: 20),
                        label: const Text(
                          'Kelola Termin Pembayaran',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardCream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rabTile(BuildContext context, String url) {
    return InkWell(
      onTap: () => _openUrl(context, url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.red.shade700),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dokumen RAB',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  SizedBox(height: 2),
                  Text(
                    'Rancangan Anggaran Biaya · Ketuk untuk buka',
                    style: TextStyle(
                        fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 18, color: Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(bool active, String title) {
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
            child: Icon(Icons.check,
                size: 14,
                color: active ? Colors.white : Colors.grey),
          ),
          const SizedBox(width: 14),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.black87
                      : Colors.black38)),
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
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}