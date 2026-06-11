// lib/modules/kontraktor/ui/tabs/kontraktor_progress_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/kontraktor_bid_detail_screen.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';

class KontraktorProgressTab extends StatefulWidget {
  const KontraktorProgressTab({super.key});

  @override
  State<KontraktorProgressTab> createState() => _KontraktorProgressTabState();
}

class _KontraktorProgressTabState extends State<KontraktorProgressTab> {
  @override
  void initState() {
    super.initState();
    context.read<ContractorProjectCubit>().fetchVendorBids();
  }

  Future<void> _refresh() async {
    await context.read<ContractorProjectCubit>().fetchVendorBids();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Progress Proyek',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: BlocBuilder<ContractorProjectCubit, ContractorProjectState>(
        builder: (context, state) {
          if (state is ContractorProjectLoading || state is ContractorProjectInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is ContractorProjectError) {
            return Center(child: Text(state.message));
          }
          if (state is ContractorProjectLoaded) {
            final allBids = state.myBids;
            // Urutkan: accepted dulu, lalu pending, lalu rejected/diabaikan
            final bids = [...allBids]..sort((a, b) {
              int rank(BidModel bid) {
                if (bid.status == 'accepted') return 0;
                final isOld = bid.status == 'pending' && bid.createdAt != null && DateTime.now().difference(bid.createdAt!).inDays > 7;
                if (bid.status == 'pending' && !isOld) return 1;
                return 2;
              }
              return rank(a).compareTo(rank(b));
            });

            if (bids.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bids.length,
              itemBuilder: (_, i) {
                final bid = bids[i];
                final project = bid.project;

                final isAccepted = bid.status == 'accepted';
                final isRejectedOrIgnored = bid.status == 'rejected' || (bid.status == 'pending' && bid.createdAt != null && DateTime.now().difference(bid.createdAt!).inDays > 7);
                final isCancelable = bid.status == 'pending' && bid.createdAt != null && DateTime.now().difference(bid.createdAt!).inHours < 24;

                final progress = project?.progressPercent ?? 0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KontraktorBidDetailScreen(bid: bid),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar Proyek
                        if (project != null && project.imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              project.imageUrls[0],
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image_outlined, color: Colors.grey),
                          ),
                        const SizedBox(height: 16),

                        /// STATUS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project?.title ?? 'Project',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _statusChip(bid.status, bid.createdAt),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// LOKASI
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project?.location ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// HARGA BID
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardCream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Penawaran Anda',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppFormatters.formatRupiah(bid.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),

                        if (isCancelable) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmCancelBid(context, bid.id ?? ''),
                              icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                              label: const Text('Batalkan Penawaran', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],

                        if (isRejectedOrIgnored) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDeleteBid(context, bid.id ?? ''),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              label: const Text('Hapus Penawaran', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],

                        if (isAccepted) ...[
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress Pembangunan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$progress%',
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
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress / 100.0,
                              minHeight: 8,
                              backgroundColor: AppColors.cardCream,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _statusChip(String status, DateTime? createdAt) {
    final isOldPending = status == 'pending' && createdAt != null && DateTime.now().difference(createdAt).inDays > 7;
    Color color;
    String label;

    if (isOldPending || status == 'rejected') {
      color = Colors.red;
      label = isOldPending ? 'Diabaikan' : 'Ditolak';
    } else if (status == 'accepted') {
      color = Colors.green;
      label = 'Diterima';
    } else {
      color = Colors.orange;
      label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBid(BuildContext context, String bidId) async {
    if (bidId.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Hapus Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
          ],
        ),
        content: const Text(
          'Penawaran ini sudah tidak aktif.\nApakah Anda yakin ingin menghapusnya secara permanen?',
          style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ContractorProjectCubit>();
    final success = await provider.deleteBid(bidId: bidId);

    if (!mounted) return;

    if (success) {
      _refresh(); // refresh the list
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Penawaran Berhasil Dihapus',
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus penawaran.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmCancelBid(BuildContext context, String bidId) async {
    if (bidId.isEmpty) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text('Batalkan Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan penawaran ini?\nAnda masih bisa mengajukan penawaran baru setelah dibatalkan.',
          style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade50,
              foregroundColor: Colors.orange.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ContractorProjectCubit>();
    final success = await provider.deleteBid(bidId: bidId);

    if (!mounted) return;

    if (success) {
      _refresh(); // refresh the list
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Penawaran Berhasil Dibatalkan',
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membatalkan penawaran.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Aktivitas Proyek',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajukan penawaran ke proyek klien agar progress pekerjaan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber),
                  SizedBox(width: 10),
                  Text(
                    'Cari proyek dan mulai bidding',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
