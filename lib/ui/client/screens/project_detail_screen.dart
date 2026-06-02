import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/bid_model.dart';
import '../../../data/providers/project_provider.dart';
import 'bid_detail_screen.dart';
import 'client_payment_terms_screen.dart';

// ── Enum Opsi Sorting ──
enum BidSortOption {
  newest,
  priceLow,
  priceHigh,
  experienceHigh,
  ratingHigh,
  ratingLow,
}

extension BidSortOptionLabel on BidSortOption {
  String get label {
    switch (this) {
      case BidSortOption.newest:
        return 'Terbaru';
      case BidSortOption.priceLow:
        return 'Harga Termurah';
      case BidSortOption.priceHigh:
        return 'Harga Termahal';
      case BidSortOption.experienceHigh:
        return 'Pengalaman Terlama';
      case BidSortOption.ratingHigh:
        return 'Rating Tertinggi';
      case BidSortOption.ratingLow:
        return 'Rating Terendah';
    }
  }

  IconData get icon {
    switch (this) {
      case BidSortOption.newest:
        return Icons.access_time_rounded;
      case BidSortOption.priceLow:
        return Icons.arrow_downward_rounded;
      case BidSortOption.priceHigh:
        return Icons.arrow_upward_rounded;
      case BidSortOption.experienceHigh:
        return Icons.workspace_premium_rounded;
      case BidSortOption.ratingHigh:
        return Icons.star_rounded;
      case BidSortOption.ratingLow:
        return Icons.star_outline_rounded;
    }
  }
}

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Future<List<BidModel>> _bidsFuture;
  late ProjectModel _project;

  // State Filter Aktif
  BidSortOption _sortOption = BidSortOption.newest;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadBids();
  }

  void _loadBids() {
    _bidsFuture = Provider.of<ProjectProvider>(
      context,
      listen: false,
    ).fetchProjectBids(_project.id ?? '');
  }

  void _refresh() {
    setState(() => _loadBids());
  }

  // Fungsi Logika Sorting di Sisi Client
  List<BidModel> _sortBids(List<BidModel> bids) {
    final sorted = List<BidModel>.from(bids);
    switch (_sortOption) {
      case BidSortOption.newest:
        sorted.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        break;
      case BidSortOption.priceLow:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case BidSortOption.priceHigh:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case BidSortOption.experienceHigh:
        sorted.sort((a, b) {
          final expA = a.vendorExperienceYears ?? -1;
          final expB = b.vendorExperienceYears ?? -1;
          return expB.compareTo(expA); // Banyak ke sedikit
        });
        break;
      case BidSortOption.ratingHigh:
        sorted.sort((a, b) {
          final rA = a.vendorRating ?? -1.0;
          final rB = b.vendorRating ?? -1.0;
          return rB.compareTo(rA);
        });
        break;
      case BidSortOption.ratingLow:
        sorted.sort((a, b) {
          final rA = a.vendorRating;
          final rB = b.vendorRating;
          if (rA == null && rB == null) return 0;
          if (rA == null) return 1; // Taruh yang null di paling bawah
          if (rB == null) return -1;
          return rA.compareTo(rB);
        });
        break;
    }
    return sorted;
  }

  void _openBidDetail(BidModel bid) {
    final isInProgress = _project.status == 'in_progress';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BidDetailScreen(
          bid: bid,
          projectBudget: _project.budget,
          isProjectInProgress: isInProgress,
          onAccepted: () {
            setState(() {
              _project = _project.copyWith(status: 'in_progress');
            });
            _refresh();
          },
          onRejected: _refresh,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(
        current: _sortOption,
        onSelected: (opt) {
          setState(() => _sortOption = opt);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _project.status == 'in_progress';

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
          'Detail Proyek',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Proyek ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                image: _project.imageUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_project.imageUrls[0]),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isInProgress ? Colors.blue : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isInProgress ? 'BERJALAN' : 'LIVE TENDER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _project.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ${AppFormatters.formatRupiah(_project.budget)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Info Bangunan ──
            const Text(
              'Informasi Bangunan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  Icons.square_foot,
                  '${_project.buildingSize.toStringAsFixed(0)} m²',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.layers, '${_project.floors} Lantai'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.bed, '${_project.bedrooms} Kamar'),
              ],
            ),
            const SizedBox(height: 32),

            // ── Header Daftar Bid + Tombol Filter Berwarna Dinamis ──
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar Penawaran (Bids)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isInProgress)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Proyek Berjalan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _sortOption != BidSortOption.newest
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _sortOption != BidSortOption.newest
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: _sortOption != BidSortOption.newest
                              ? Colors.white
                              : Colors.black54,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _sortOption == BidSortOption.newest
                              ? 'Filter'
                              : _sortOption.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _sortOption != BidSortOption.newest
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Notifikasi Filter Aktif ──
            if (_sortOption != BidSortOption.newest) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(_sortOption.icon, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Urutan: ${_sortOption.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _sortOption = BidSortOption.newest),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // ── Builder List Data ──
            FutureBuilder<List<BidModel>>(
              future: _bidsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                final rawBids = snapshot.data ?? [];
                final bids = _sortBids(rawBids);

                if (bids.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada penawaran masuk',
                            style: TextStyle(
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: bids.asMap().entries.map((e) {
                    return _buildBidCard(e.value, e.key + 1);
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── Penyesuaian Rank Number & Multi-chips ──
  Widget _buildBidCard(BidModel bid, int rank) {
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

    final priceColor = bid.price <= _project.budget
        ? Colors.green.shade700
        : bid.price <= _project.budget * 1.1
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
            color: Colors.black.withOpacity(0.03),
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
                  color: rank == 1 && _sortOption != BidSortOption.newest
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
                      color: rank == 1 && _sortOption != BidSortOption.newest
                          ? Colors.white
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(
                  (bid.vendorName?.isNotEmpty == true)
                      ? bid.vendorName![0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
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
                  color: statusColor.withOpacity(0.12),
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
              onPressed: () => _openBidDetail(bid),
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
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.04),
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
                        projectId: _project.id ?? '',
                        dealPrice: bid.price,
                        projectTitle: _project.title,
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
        color: color.withOpacity(0.08),
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

// ── Bottom Sheet Component ──
class _FilterSheet extends StatelessWidget {
  final BidSortOption current;
  final ValueChanged<BidSortOption> onSelected;

  const _FilterSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Urutkan Penawaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih kriteria untuk mengurutkan daftar kontraktor',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 20),
            ...BidSortOption.values.map(
              (opt) => _FilterOption(
                option: opt,
                isSelected: opt == current,
                onTap: () => onSelected(opt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final BidSortOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option.icon,
                size: 18,
                color: isSelected ? AppColors.primary : Colors.black45,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
