// lib/modules/kontraktor/ui/tabs/progress/progress_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/bid_detail/bid_detail_screen.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';

import 'widgets/progress_bid_card.dart';
import 'widgets/progress_empty_state.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
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
              return const ProgressEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bids.length,
              itemBuilder: (_, i) {
                final bid = bids[i];
                return ProgressBidCard(
                  bid: bid,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BidDetailScreen(bid: bid),
                      ),
                    );
                  },
                  onCancelTap: () => _confirmCancelBid(context, bid.id ?? ''),
                  onDeleteTap: () => _confirmDeleteBid(context, bid.id ?? ''),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
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
}
