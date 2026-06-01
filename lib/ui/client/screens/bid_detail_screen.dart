import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bid_model.dart';
import '../../../data/providers/project_provider.dart';

/// Screen client untuk melihat detail satu penawaran dari kontraktor.
/// Menampilkan: harga vs budget, estimasi bulan, RAB, notes kontraktor,
/// dan tombol Terima / Tolak di bagian bawah.
class BidDetailScreen extends StatelessWidget {
  final BidModel bid;

  /// Budget proyek dari client — di-pass langsung dari ProjectDetailScreen
  /// agar tidak bergantung pada bid.project (yang bisa null).
  final double projectBudget;

  /// True jika proyek sudah in_progress (ada bid lain yang sudah diterima).
  /// Digunakan untuk menyembunyikan tombol Terima/Tolak pada bid pending.
  final bool isProjectInProgress;

  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const BidDetailScreen({
    super.key,
    required this.bid,
    required this.projectBudget,
    this.isProjectInProgress = false,
    this.onAccepted,
    this.onRejected,
  });

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  Future<void> _handleAccept(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terima Penawaran?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Anda akan menerima penawaran dari ${bid.vendorName ?? 'kontraktor'} '
          'sebesar ${AppFormatters.formatRupiah(bid.price)}.\n\n'
          'Proyek akan berubah status menjadi "Berjalan".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final ok = await provider.acceptBid(
      bidId: bid.id ?? '',
      projectId: bid.projectId,
    );

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Penawaran diterima! Proyek mulai berjalan.'),
          backgroundColor: Colors.green,
        ),
      );
      onAccepted?.call();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menerima penawaran, coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tolak Penawaran?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Penawaran dari ${bid.vendorName ?? 'kontraktor'} akan ditolak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final ok = await provider.rejectBid(bidId: bid.id ?? '');

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penawaran ditolak.')),
      );
      onRejected?.call();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menolak penawaran, coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = bid.status == 'pending';
    final isAccepted = bid.status == 'accepted';

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penawaran',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _statusChip(bid.status)),
          ),
        ],
      ),

      // ── Tombol sticky di bawah (hanya jika pending DAN proyek belum in_progress) ──
      bottomNavigationBar: isPending && !isProjectInProgress
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(context),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.redAccent),
                      label: const Text('Tolak',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(context),
                      icon: const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white),
                      label: const Text('Terima Penawaran',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────────────────────────────────
            // SECTION 1: Identitas Kontraktor
            // ──────────────────────────────────────
            _sectionLabel('Kontraktor'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecor(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      (bid.vendorName?.isNotEmpty == true)
                          ? bid.vendorName![0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bid.vendorName ?? 'Kontraktor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: Colors.black38),
                            const SizedBox(width: 4),
                            Text(
                              bid.createdAt != null
                                  ? 'Dikirim ${AppFormatters.timeAgo(bid.createdAt)}'
                                  : 'Waktu tidak diketahui',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ──────────────────────────────────────
            // SECTION 2: Perbandingan Harga
            // ──────────────────────────────────────
            _sectionLabel('Penawaran Harga'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecor(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _priceTile(
                          label: 'Budget Anda',
                          value: AppFormatters.formatRupiah(projectBudget),
                          icon: Icons.account_balance_wallet_outlined,
                          highlight: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _priceTile(
                          label: 'Harga Penawaran',
                          value: AppFormatters.formatRupiah(bid.price),
                          icon: Icons.payments_outlined,
                          highlight: true,
                          valueColor: _priceColor(bid.price, projectBudget),
                        ),
                      ),
                    ],
                  ),
                  if (projectBudget > 0) ...[
                    const SizedBox(height: 14),
                    _priceDiffBanner(bid.price, projectBudget),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ──────────────────────────────────────
            // SECTION 3: Estimasi Waktu Pengerjaan
            // ──────────────────────────────────────
            if (bid.estimationMonths != null) ...[
              _sectionLabel('Estimasi Waktu Pengerjaan'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _cardDecor(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.schedule_rounded,
                          color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Durasi Pengerjaan',
                            style: TextStyle(
                                fontSize: 12, color: Colors.black45)),
                        const SizedBox(height: 4),
                        Text(
                          '${bid.estimationMonths} Bulan',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '≈ ${(bid.estimationMonths! / 12 * 10).round() / 10} tahun',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ──────────────────────────────────────
            // SECTION 4: Dokumen RAB
            // ──────────────────────────────────────
            _sectionLabel('Dokumen RAB (Rancangan Anggaran Biaya)'),
            const SizedBox(height: 10),
            if (bid.rabUrl != null && bid.rabUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _openUrl(context, bid.rabUrl!),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.red.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.red.shade600, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dokumen RAB Kontraktor',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tinjau rincian anggaran biaya · PDF / Excel',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Buka',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded,
                                size: 13, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.black26, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Kontraktor tidak melampirkan dokumen RAB',
                      style: TextStyle(fontSize: 13, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ──────────────────────────────────────
            // SECTION 5: Catatan / Notes Kontraktor
            // ──────────────────────────────────────
            _sectionLabel('Catatan dari Kontraktor'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _cardDecor(),
              child: bid.message != null && bid.message!.isNotEmpty
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.format_quote_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bid.message!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.65,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.black26, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tidak ada catatan dari kontraktor',
                          style: TextStyle(
                              fontSize: 13, color: Colors.black38),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // ──────────────────────────────────────
            // SECTION 6: Banner jika sudah diterima
            // ──────────────────────────────────────
            if (isAccepted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Penawaran ini sudah diterima · Proyek sedang berjalan',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),

            // ── Banner jika proyek sudah berjalan (bid pending tapi tidak bisa diterima) ──
            if (isPending && isProjectInProgress)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Proyek ini sudah berjalan · Penawaran Anda tidak dapat diproses lagi',
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            if (isPending) const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      );

  Widget _priceTile({
    required String label,
    required String value,
    required IconData icon,
    required bool highlight,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.cardCream,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: AppColors.primary.withOpacity(0.2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.black38),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceDiffBanner(double bidPrice, double budget) {
    final diff = bidPrice - budget;
    final isOver = diff > 0;
    final isEqual = diff == 0;

    final color = isOver
        ? Colors.orange.shade700
        : isEqual
            ? Colors.blue.shade700
            : Colors.green.shade700;
    final bg = isOver
        ? Colors.orange.shade50
        : isEqual
            ? Colors.blue.shade50
            : Colors.green.shade50;
    final icon = isOver
        ? Icons.trending_up_rounded
        : isEqual
            ? Icons.trending_flat_rounded
            : Icons.trending_down_rounded;
    final label = isEqual
        ? 'Tepat sesuai budget Anda'
        : isOver
            ? '${AppFormatters.formatRupiah(diff.abs())} di atas budget Anda'
            : '${AppFormatters.formatRupiah(diff.abs())} di bawah budget Anda';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _priceColor(double price, double budget) {
    if (budget <= 0) return Colors.black87;
    if (price > budget * 1.1) return Colors.orange.shade700;
    if (price <= budget) return Colors.green.shade700;
    return Colors.black87;
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}