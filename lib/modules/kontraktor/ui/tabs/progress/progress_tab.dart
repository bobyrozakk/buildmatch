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
import 'widgets/filter_sort_sheet.dart';
import 'widgets/progress_search_row.dart';
import 'widgets/progress_filter_chips.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'Aktif'; // 'Aktif' | 'Menunggu' | 'Riwayat'
  String _selectedSort = 'terbaru'; // 'terbaru' | 'terlama' | 'termahal' | 'termurah' | 'progress'

  final List<String> _tabs = const ['Aktif', 'Menunggu', 'Riwayat'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ContractorProjectCubit>().fetchVendorBids();
  }

  bool _isOldPending(BidModel bid) {
    return bid.status == 'pending' &&
        bid.createdAt != null &&
        DateTime.now().difference(bid.createdAt!).inDays > 7;
  }

  List<BidModel> _getFilteredAndSortedBids(List<BidModel> rawBids, String selectedTab) {
    // 1. Filter berdasarkan tab
    List<BidModel> bids = [];
    if (selectedTab == 'Aktif') {
      bids = rawBids.where((bid) => bid.status == 'accepted').toList();
    } else if (selectedTab == 'Menunggu') {
      bids = rawBids.where((bid) => bid.status == 'pending' && !_isOldPending(bid)).toList();
    } else {
      bids = rawBids.where((bid) => bid.status == 'rejected' || _isOldPending(bid)).toList();
    }

    // 2. Filter berdasarkan kata kunci pencarian (Search Query)
    if (_searchQuery.isNotEmpty) {
      bids = bids.where((bid) {
        final title = bid.project?.title.toLowerCase() ?? '';
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 3. Urutkan berdasarkan kriteria sorting
    bids.sort((a, b) {
      if (_selectedSort == 'terbaru') {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      } else if (_selectedSort == 'terlama') {
        final dateA = a.createdAt ?? DateTime(1970);
        final dateB = b.createdAt ?? DateTime(1970);
        return dateA.compareTo(dateB);
      } else if (_selectedSort == 'termahal') {
        return b.price.compareTo(a.price);
      } else if (_selectedSort == 'termurah') {
        return a.price.compareTo(b.price);
      } else if (_selectedSort == 'progress') {
        final progressA = a.project?.progressPercent ?? 0;
        final progressB = b.project?.progressPercent ?? 0;
        return progressB.compareTo(progressA);
      }
      return 0;
    });

    return bids;
  }

  void _openFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return FilterSortSheet(
          selectedSort: _selectedSort,
          showProgressSort: _selectedTab == 'Aktif', // Hanya tampilkan sorting progress pada tab Aktif
          onSortApplied: (newSort) {
            setState(() {
              _selectedSort = newSort;
            });
          },
        );
      },
    );
  }

  Widget _buildTabContent(List<BidModel> rawBids, String selectedTab) {
    final list = _getFilteredAndSortedBids(rawBids, selectedTab);

    if (list.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return ProgressEmptyState(
          title: 'Tidak Ditemukan',
          description: 'Tidak ada proyek dengan kata kunci "$_searchQuery" di tab ini.',
          icon: Icons.search_off_rounded,
        );
      }

      if (selectedTab == 'Aktif') {
        return const ProgressEmptyState(
          title: 'Belum Ada Proyek Aktif',
          description: 'Penawaran Anda belum ada yang diterima. Telusuri proyek baru dan mulailah mengajukan bid!',
          icon: Icons.engineering_rounded,
        );
      } else if (selectedTab == 'Menunggu') {
        return const ProgressEmptyState(
          title: 'Tidak Ada Penawaran Aktif',
          description: 'Tidak ada penawaran proyek yang sedang menunggu persetujuan klien saat ini.',
          icon: Icons.hourglass_empty_rounded,
        );
      } else {
        return const ProgressEmptyState(
          title: 'Riwayat Kosong',
          description: 'Anda tidak memiliki riwayat penawaran yang ditolak atau kedaluwarsa.',
          icon: Icons.history_toggle_off_rounded,
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final bid = list[i];
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
          onCancelTap: () => _confirmCancelBid(bid.id ?? ''),
          onDeleteTap: () => _confirmDeleteBid(bid.id ?? ''),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Progress Proyek',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is ContractorProjectLoaded) {
            final allBids = state.myBids;

            // Hitung jumlah item per kategori tab secara dinamis
            final activeCount = allBids.where((bid) => bid.status == 'accepted').length;
            final pendingCount = allBids.where((bid) => bid.status == 'pending' && !_isOldPending(bid)).length;
            final historyCount = allBids.where((bid) => bid.status == 'rejected' || _isOldPending(bid)).length;

            final tabCounts = {
              'Aktif': activeCount,
              'Menunggu': pendingCount,
              'Riwayat': historyCount,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Bar Pencarian & Filter Urutan
                ProgressSearchRow(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  onSortTap: _openFilterSortSheet,
                  isSortActive: _selectedSort != 'terbaru',
                ),

                // 2. Kategori Tab Chips Kecil di bawah Search Bar
                ProgressFilterChips(
                  tabs: _tabs,
                  selectedTab: _selectedTab,
                  tabCounts: tabCounts,
                  onTabSelected: (tab) {
                    setState(() {
                      _selectedTab = tab;
                      // Reset sort ke default jika tab berpindah dan sort saat ini adalah 'progress' tapi bukan tab Aktif
                      if (tab != 'Aktif' && _selectedSort == 'progress') {
                        _selectedSort = 'terbaru';
                      }
                    });
                  },
                ),

                const SizedBox(height: 4),

                // 3. Konten Daftar Proyek
                Expanded(
                  child: _buildTabContent(allBids, _selectedTab),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _confirmDeleteBid(String bidId) async {
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

  Future<void> _confirmCancelBid(String bidId) async {
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
