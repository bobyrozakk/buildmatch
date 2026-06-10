import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/client/logic/project/project_state.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/kontraktor_detail_proyek_screen.dart';
import 'package:buildmatch/ui/shared/widgets/location_picker_sheet.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';

class KontraktorProyekTab extends StatefulWidget {
  const KontraktorProyekTab({super.key});

  @override
  State<KontraktorProyekTab> createState() => _KontraktorProyekTabState();
}

class _KontraktorProyekTabState extends State<KontraktorProyekTab> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  LocationResult _location = const LocationResult();

  static const _filters = ['Semua', 'Baru', 'Penawaran Diajukan', 'Penawaran Diterima', 'Budget Tinggi'];

  bool get _isBidFilter => _selectedFilter == 'Penawaran Diajukan' || _selectedFilter == 'Penawaran Diterima';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final p = context.read<ProjectCubit>();
    p.fetchAvailableProjects();
    p.fetchVendorBids();
  }

  Future<void> _refresh() async {
    final p = context.read<ProjectCubit>();
    await Future.wait([p.fetchAvailableProjects(), p.fetchVendorBids()]);
  }

  void _openDetail(ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KontraktorDetailProyekScreen(project: p)),
    ).then((_) => _refresh());
  }

  Future<void> _showLocationPicker() async {
    final result = await LocationPickerSheet.show(context, initial: _location);
    if (result != null) setState(() => _location = result);
  }

  bool _matchesSearchAndLocation(ProjectModel? p) {
    if (p == null) return false;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final ok = p.title.toLowerCase().contains(q) ||
          (p.location?.toLowerCase().contains(q) ?? false) ||
          (p.description?.toLowerCase().contains(q) ?? false);
      if (!ok) return false;
    }
    final locFilter = _location.city ?? _location.province;
    if (locFilter != null) {
      if (!(p.location?.toLowerCase().contains(locFilter.toLowerCase()) ?? false)) return false;
    }
    return true;
  }

  List<ProjectModel> _applyProjectFilters(List<ProjectModel> projects) {
    var filtered = projects.where(_matchesSearchAndLocation).toList();
    if (_selectedFilter == 'Baru') {
      filtered = filtered.where((p) =>
          p.createdAt != null && DateTime.now().difference(p.createdAt!).inDays <= 3).toList();
    } else if (_selectedFilter == 'Budget Tinggi') {
      filtered.sort((a, b) => b.budget.compareTo(a.budget));
    }
    return filtered;
  }

  List<BidModel> _applyBidFilters(List<BidModel> bids) {
    final wantStatus = _selectedFilter == 'Penawaran Diajukan' ? 'pending' : 'accepted';
    return bids
        .where((b) => b.status == wantStatus)
        .where((b) => _matchesSearchAndLocation(b.project))
        .toList();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: BlocBuilder<ProjectCubit, ProjectState>(
          builder: (context, state) {
            if (state is ProjectLoading || state is ProjectInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is ProjectError) {
              return Center(child: Text(state.message));
            }
            if (state is ProjectLoaded) {
              final allProjects = state.availableProjects;
              final allBids = state.vendorBids;

              final filteredProjects = _isBidFilter ? const <ProjectModel>[] : _applyProjectFilters(allProjects);
              final filteredBids = _isBidFilter ? _applyBidFilters(allBids) : const <BidModel>[];
              final itemCount = _isBidFilter ? filteredBids.length : filteredProjects.length;
              final headerCount = _isBidFilter ? allBids.where((b) => b.status == (_selectedFilter == 'Penawaran Diajukan' ? 'pending' : 'accepted')).length : allProjects.length;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      sliver: SliverToBoxAdapter(child: _buildHeader(headerCount)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      sliver: SliverToBoxAdapter(child: _buildSearchRow()),
                    ),
                    SliverToBoxAdapter(child: _buildFilterChips()),
                    if (itemCount == 0)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _isBidFilter
                                  ? _buildBidCard(filteredBids[i])
                                  : _buildProjectCard(filteredProjects[i], hasBid: allBids.any((b) => b.projectId == filteredProjects[i].id)),
                            ),
                            childCount: itemCount,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // --- HEADER ---

  Widget _buildHeader(int totalCount) {
    final title = _isBidFilter ? _selectedFilter : 'Proyek Tersedia';
    final subtitle = _isBidFilter ? '$totalCount penawaran' : '$totalCount proyek aktif';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  // --- SEARCH + LOCATION ---

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Cari proyek...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.black38),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(_location.short, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- FILTER CHIPS ---

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _selectedFilter == f;
          return Padding(
            padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- PROJECT CARD ---

  Widget _buildProjectCard(ProjectModel p, {bool hasBid = false}) {
    return GestureDetector(
      onTap: () => _openDetail(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Proyek
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: p.imageUrls.isNotEmpty
                  ? Image.network(
                      p.imageUrls[0],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 12),
            // Top row: budget + time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        AppFormatters.formatRupiah(p.budget),
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_timeAgo(p.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p.location ?? 'Lokasi tidak diketahui',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              p.description ?? 'Tidak ada deskripsi.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            // Bottom: client + cta
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.cardCream,
                  child: Text(
                    _initials(p.clientName ?? 'K'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.clientName ?? 'Klien',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          const Text('4.9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          Text(
                            '(${p.progressPercent} Proyek)',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _openDetail(p), // Selalu bisa diklik untuk melihat detail/membatalkan
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasBid ? Colors.grey.shade400 : AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(
                    hasBid ? 'Sudah Menawar' : 'Ajukan Penawaran',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- BID CARD (PENAWARAN DIAJUKAN / DITERIMA) ---

  Widget _buildBidCard(BidModel bid) {
    final p = bid.project;
    final isAccepted = bid.status == 'accepted';
    final isRejected = bid.status == 'rejected' || (bid.status == 'pending' && bid.createdAt != null && DateTime.now().difference(bid.createdAt!).inDays > 7);
    final statusLabel = isAccepted ? 'Diterima' : (isRejected ? 'Diabaikan' : 'Menunggu');
    final statusColor = isAccepted ? Colors.green : (isRejected ? Colors.red : Colors.orange);
    final statusIcon = isAccepted ? Icons.check_circle_rounded : (isRejected ? Icons.cancel_outlined : Icons.access_time_rounded);

    return GestureDetector(
      onTap: p == null ? null : () => _openDetail(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner proyek dibatalkan ──
            if (p?.status == 'cancelled')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded, size: 15, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Proyek ini telah dibatalkan oleh klien',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Gambar Proyek
            if (p != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: p.imageUrls.isNotEmpty
                    ? Image.network(
                        p.imageUrls[0],
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 140,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
              ),
            if (p != null) const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_timeAgo(bid.createdAt), style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              p?.title ?? 'Proyek tidak tersedia',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    p?.location ?? '-',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Penawaran Anda', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatRupiah(bid.price),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                if (p != null && p.budget > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Budget Klien', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatRupiah(p.budget),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- EMPTY STATE ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Tidak ada proyek ditemukan', style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Coba ubah filter atau kata kunci pencarian', style: TextStyle(fontSize: 12, color: Colors.black38)),
        ],
      ),
    );
  }

  // --- HELPERS ---

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 30).floor()} bulan lalu';
  }

  String _initials(String name) {
    if (name.isEmpty) return 'K';
    final parts = name.trim().split(' ');
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }
}
