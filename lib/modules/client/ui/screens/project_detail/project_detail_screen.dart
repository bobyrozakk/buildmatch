import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/modules/client/ui/screens/bid_detail/bid_detail_screen.dart';
import 'widgets/project_bid_filter_sheet.dart';
import 'widgets/project_bid_card.dart';

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
      builder: (ctx) => ProjectBidFilterSheet(
        current: _sortOption,
        onSelected: (opt) {
          setState(() => _sortOption = opt);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildGridSpecItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = _project.status == 'in_progress';
    final landDimensions = (_project.landCustomPanjang != null && _project.landCustomLebar != null)
        ? ' (${_project.landCustomPanjang!.toStringAsFixed(0)}×${_project.landCustomLebar!.toStringAsFixed(0)} m)'
        : '';

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Proyek Premium ──
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      image: _project.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_project.imageUrls[0]),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _project.imageUrls.isEmpty
                        ? Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, Color(0xFFC84B20)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.home_work_rounded,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInProgress ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isInProgress ? 'PROYEK BERJALAN' : 'TENDER TERBUKA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _project.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Budget: ${AppFormatters.formatRupiah(_project.budget)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Info Spesifikasi Detail ──
            const Text(
              'Detail Spesifikasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildGridSpecItem(
                  Icons.square_foot_rounded,
                  '${_project.buildingSize.toStringAsFixed(0)} m²',
                  'Luas Bangunan',
                ),
                _buildGridSpecItem(
                  Icons.landscape_rounded,
                  '${_project.landSize.toStringAsFixed(0)} m²$landDimensions',
                  'Luas Tanah',
                ),
                _buildGridSpecItem(
                  Icons.layers_rounded,
                  '${_project.floors} Lantai',
                  'Tinggi Bangunan',
                ),
                _buildGridSpecItem(
                  Icons.palette_rounded,
                  _project.houseStyle,
                  'Gaya Desain',
                ),
                _buildGridSpecItem(
                  Icons.bed_rounded,
                  '${_project.bedrooms} Kamar',
                  'Kamar Tidur',
                ),
                _buildGridSpecItem(
                  Icons.bathtub_rounded,
                  '${_project.bathrooms} Ruang',
                  'Kamar Mandi',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Deskripsi Proyek ──
            const Text(
              'Deskripsi Proyek',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _project.description != null && _project.description!.trim().isNotEmpty
                    ? _project.description!
                    : 'Tidak ada deskripsi proyek.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Lokasi Proyek ──
            const Text(
              'Lokasi Proyek',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _project.location != null && _project.location!.trim().isNotEmpty
                              ? _project.location!
                              : 'Lokasi tidak ditentukan.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_project.latitude != null && _project.longitude != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final mapUrl = 'https://www.google.com/maps/search/?api=1&query=${_project.latitude},${_project.longitude}';
                        _openUrl(context, mapUrl);
                      },
                      icon: const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                      label: const Text(
                        'Buka Google Maps',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Dokumen Referensi PDF ──
            if (_project.referencePdfUrl != null && _project.referencePdfUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Dokumen Pendukung',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PDF Referensi Proyek',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketuk untuk membuka dokumen referensi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
                      onPressed: () => _openUrl(context, _project.referencePdfUrl!),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Header Daftar Bid + Tombol Filter Berwarna Dinamis ──
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar Penawaran (Bids)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                      color: Colors.blue.withValues(alpha: 0.1),
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
                final bool hasAccepted = rawBids.any((b) => b.status == 'accepted');
                final bool isAcceptedOrInProgress = _project.status == 'in_progress' || hasAccepted;

                final List<BidModel> filteredRawBids;
                if (isAcceptedOrInProgress) {
                  filteredRawBids = rawBids.where((b) => b.status == 'accepted').toList();
                } else {
                  filteredRawBids = rawBids;
                }

                final bids = _sortBids(filteredRawBids);

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
                    return ProjectBidCard(
                      bid: e.value,
                      rank: e.key + 1,
                      sortOption: _sortOption,
                      project: _project,
                      onOpenBidDetail: () => _openBidDetail(e.value),
                    );
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
}
