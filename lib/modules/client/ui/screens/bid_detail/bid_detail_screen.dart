import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/ui/shared/screens/contractor_chat_detail_screen.dart';
import 'widgets/bid_price_tile.dart';
import 'widgets/bid_price_diff_banner.dart';
import 'widgets/bid_status_chip.dart';
import 'widgets/bid_contractor_card.dart';
import 'widgets/bid_rab_card.dart';

class BidDetailScreen extends StatelessWidget {
  final BidModel bid;
  final double projectBudget;
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
        title: const Text('Terima Penawaran?', style: TextStyle(fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Tolak Penawaran?', style: TextStyle(fontWeight: FontWeight.bold)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _handleContactContractor(BuildContext context) async {
    final chatCubit = context.read<ChatCubit>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final chatId = await chatCubit.getOrCreateChat(
        bid.vendorId,
        projectId: bid.projectId,
        forceStatus: 'accepted',
      );

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        if (chatId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContractorChatDetailScreen(
                chatId: chatId,
                receiverName: bid.vendorName ?? 'Kontraktor',
                receiverId: bid.vendorId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membuat ruang obrolan.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      );

  Color _priceColor(double price, double budget) {
    if (budget <= 0) return Colors.black87;
    if (price > budget * 1.1) return Colors.orange.shade700;
    if (price <= budget) return Colors.green.shade700;
    return Colors.black87;
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: BidStatusChip(status: bid.status)),
          ),
        ],
      ),

      // ── Tombol sticky di bawah ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending && !isProjectInProgress) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(context),
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                      label: const Text(
                        'Tolak',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAccept(context),
                      icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Terima Penawaran',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleContactContractor(context),
                icon: const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Hubungi Kontraktor',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Identitas Kontraktor
            _sectionLabel('Kontraktor'),
            const SizedBox(height: 10),
            BidContractorCard(bid: bid),
            const SizedBox(height: 20),

            // Perbandingan Harga
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
                        child: BidPriceTile(
                          label: 'Budget Anda',
                          value: AppFormatters.formatRupiah(projectBudget),
                          icon: Icons.account_balance_wallet_outlined,
                          highlight: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BidPriceTile(
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
                    BidPriceDiffBanner(bidPrice: bid.price, budget: projectBudget),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Estimasi Waktu Pengerjaan
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
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Durasi Pengerjaan', style: TextStyle(fontSize: 12, color: Colors.black45)),
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
                          style: const TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Dokumen RAB
            _sectionLabel('Dokumen RAB (Rancangan Anggaran Biaya)'),
            const SizedBox(height: 10),
            BidRabCard(
              rabUrl: bid.rabUrl,
              onTap: () => _openUrl(context, bid.rabUrl!),
            ),
            const SizedBox(height: 20),

            // Catatan / Notes Kontraktor
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 18),
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
                        Icon(Icons.info_outline_rounded, color: Colors.black26, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tidak ada catatan dari kontraktor',
                          style: TextStyle(fontSize: 13, color: Colors.black38),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Banner jika sudah diterima
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
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Penawaran ini sudah diterima · Proyek sedang berjalan',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Banner jika proyek sudah berjalan
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
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
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
}
