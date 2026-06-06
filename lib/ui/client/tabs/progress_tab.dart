import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/bid_model.dart';
import '../screens/project_detail_screen.dart';
import '../screens/create_project_screen.dart';
import '../screens/architect_offer_detail_screen.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

class ProgressTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const ProgressTab({super.key, this.onSwitchTab});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  late Future<List<ProjectModel>> _projectsFuture;
  late Future<List<ProjectModel>> _draftsFuture;
  late Future<List<BidModel>> _incomingBidsFuture;
  late Future<List<BidModel>> _architectBidsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    setState(() {
      _projectsFuture = provider.fetchProjects();
      _draftsFuture = provider.fetchDraftProjects();
      _incomingBidsFuture = provider.fetchClientIncomingBids();
      _architectBidsFuture = provider.fetchClientArchitectBids();
    });
  }

  // --- HAPUS DRAFT DENGAN KONFIRMASI ---
  Future<void> _confirmDeleteDraft(ProjectModel draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Draft?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Draft "${draft.title}" akan dihapus permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && draft.id != null) {
      final provider = Provider.of<ProjectProvider>(context, listen: false);
      final success = await provider.deleteDraft(draft.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _refresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus draft'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Proyek Saya",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── SECTION PENAWARAN KONTRAKTOR MASUK (GROUPED PER PROYEK) ──
            FutureBuilder<List<BidModel>>(
              future: _incomingBidsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final bids = snapshot.data ?? [];
                if (bids.isEmpty) return const SizedBox.shrink();

                // Group bids by projectId
                final Map<String, List<BidModel>> grouped = {};
                for (final bid in bids) {
                  grouped.putIfAbsent(bid.projectId, () => []).add(bid);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.gavel_rounded,
                              size: 16, color: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Penawaran Kontraktor (${grouped.length} proyek)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Satu card per proyek
                    ...grouped.entries.map((entry) {
                      final projectBids = entry.value;
                      final firstBid = projectBids.first;
                      final project = firstBid.project;
                      return _buildGroupedBidCard(
                        projectBids: projectBids,
                        project: project,
                      );
                    }),

                    const SizedBox(height: 8),
                    const Divider(height: 32),
                  ],
                );
              },
            ),

            // ── SECTION KONSULTASI ARSITEK ──
            FutureBuilder<List<BidModel>>(
              future: _architectBidsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final architectBids = snapshot.data ?? [];
                if (architectBids.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.architecture_rounded,
                              size: 16, color: Colors.purple),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Konsultasi Arsitek (${architectBids.length})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...architectBids.map((bid) => _buildArchitectBidCard(bid)),

                    const SizedBox(height: 8),
                    const Divider(height: 32),
                  ],
                );
              },
            ),

            // ── SECTION DRAFT ──
            FutureBuilder<List<ProjectModel>>(
              future: _draftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 60,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final drafts = snapshot.data ?? [];
                if (drafts.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section draft
                    Row(
                      children: [
                        const Icon(Icons.bookmark_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Draft Saya (${drafts.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List card draft
                    ...drafts.map((draft) => GestureDetector(
                      onTap: () async {
                        final val = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateProjectScreen(draft: draft),
                          ),
                        );
                        _refresh();
                        if (val == 'route_to_consultation') {
                          widget.onSwitchTab?.call(99);
                        }
                      },
                      child: _buildDraftCard(draft),
                    )),

                    const SizedBox(height: 8),
                    const Divider(height: 32),

                    // Header section proyek aktif
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 16, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          'Proyek Aktif',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            // ── SECTION PROYEK AKTIF ──
            FutureBuilder<List<ProjectModel>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final projects = snapshot.data!;
                return Column(
                  children: projects
                      .map((item) => _buildProjectCard(item))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD KONSULTASI ARSITEK ---
  Widget _buildArchitectBidCard(BidModel bid) {
    // Parse pesan arsitek (berisi title, description, revisions, duration_days)
    String offerTitle = 'Penawaran Desain';
    String offerDescription = '';
    int revisions = 0;
    int durationDays = 0;

    if (bid.message != null && bid.message!.startsWith('{')) {
      try {
        final data = jsonDecode(bid.message!);
        offerTitle = data['title'] ?? offerTitle;
        offerDescription = data['description'] ?? '';
        revisions = data['revisions'] ?? 0;
        durationDays = data['duration_days'] ?? 0;
      } catch (_) {}
    }

    final architectName = bid.vendorName ?? 'Arsitek';
    final initial = architectName.isNotEmpty ? architectName[0].toUpperCase() : 'A';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (bid.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusLabel = 'Diterima';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'Ditolak';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Dibatalkan';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.purple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (bid.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArchitectOfferDetailScreen(
                  bidId: bid.id!,
                  title: offerTitle,
                  price: bid.price,
                  description: offerDescription,
                  revisions: revisions,
                  durationDays: durationDays,
                  architectName: architectName,
                ),
              ),
            ).then((_) => _refresh());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar arsitek
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.architecture_rounded,
                                size: 13, color: Colors.purple),
                            const SizedBox(width: 4),
                            const Text(
                              'Arsitek',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          architectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Judul penawaran
              Text(
                offerTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _miniChip(
                    Icons.payments_outlined,
                    AppFormatters.formatRupiah(bid.price),
                    Colors.purple,
                  ),
                  if (durationDays > 0)
                    _miniChip(
                      Icons.schedule_rounded,
                      '$durationDays hari',
                      Colors.blue,
                    ),
                  if (revisions > 0)
                    _miniChip(
                      Icons.loop_rounded,
                      '$revisions revisi',
                      Colors.teal,
                    ),
                ],
              ),

              // Tombol lihat detail
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (bid.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchitectOfferDetailScreen(
                            bidId: bid.id!,
                            title: offerTitle,
                            price: bid.price,
                            description: offerDescription,
                            revisions: revisions,
                            durationDays: durationDays,
                            architectName: architectName,
                          ),
                        ),
                      ).then((_) => _refresh());
                    }
                  },
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: Colors.purple,
                  ),
                  label: const Text(
                    'Lihat Detail Penawaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(
                        color: Colors.purple.withOpacity(0.4), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.purple.withOpacity(0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
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

  // --- CARD GROUPED BID PER PROYEK (KONTRAKTOR) ---
  Widget _buildGroupedBidCard({
    required List<BidModel> projectBids,
    required ProjectModel? project,
  }) {
    final projectTitle = project?.title ?? projectBids.first.project?.title ?? 'Proyek';
    // Preview maks 3 kontraktor
    final previewBids = projectBids.take(3).toList();
    final remaining = projectBids.length - previewBids.length;

    // Gunakan project dari bid (bisa null jika tidak di-join)
    // Buat ProjectModel minimal untuk navigasi
    final ProjectModel? navProject = project;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header proyek ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_outlined,
                      size: 18, color: Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${projectBids.length} kontraktor menawar',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${projectBids.length} bid',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 10),

          // ── Preview 1–3 kontraktor ──
          ...previewBids.asMap().entries.map((entry) {
            final index = entry.key;
            final bid = entry.value;
            return _buildBidPreviewRow(bid, index, navProject);
          }),

          // ── Sisa kontraktor (jika > 3) ──
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Text(
                '+$remaining kontraktor lainnya',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
            ),

          // ── Tombol Lihat Detail Seluruhnya ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (navProject != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: navProject),
                      ),
                    ).then((_) => _refresh());
                  }
                },
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Lihat Detail Seluruhnya',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                      color: AppColors.primary.withOpacity(0.4), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary.withOpacity(0.04),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ROW PREVIEW SATU KONTRAKTOR ---
  Widget _buildBidPreviewRow(BidModel bid, int index, ProjectModel? project) {
    final vendorName = bid.vendorName ?? 'Kontraktor';
    final initial = vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'K';

    return InkWell(
      onTap: () {
        // Tap nama kontraktor → langsung ke ProjectDetailScreen agar bisa lihat semua bid
        if (project != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project),
            ),
          ).then((_) => _refresh());
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            // Badge nomor urut
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: index == 0
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: index == 0 ? AppColors.primary : Colors.black45,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                initial,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),

            // Nama kontraktor
            Expanded(
              child: Text(
                vendorName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Harga bid
            Text(
              AppFormatters.formatRupiah(bid.price),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  // --- CARD DRAFT ---
  Widget _buildDraftCard(ProjectModel draft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon bookmark
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bookmark_outline,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Info draft
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title.isNotEmpty ? draft.title : 'Draft Tanpa Judul',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  draft.createdAt != null
                      ? 'Disimpan ${_formatDate(draft.createdAt!)}'
                      : 'Belum dipublikasikan',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                if (draft.budget > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatRupiah(draft.budget),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tombol hapus
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400, size: 20),
            onPressed: () => _confirmDeleteDraft(draft),
            tooltip: 'Hapus draft',
          ),
        ],
      ),
    );
  }

  // --- CARD PROYEK AKTIF ---
  Widget _buildProjectCard(ProjectModel item) {
    final canAct = item.status == 'open';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: item)),
      ).then((_) => _refresh()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title.isNotEmpty ? item.title : 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusTag(item.status),
                    if (canAct) ...[
                      const SizedBox(width: 4),
                      _buildProjectActionMenu(item),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  item.location ?? 'Lokasi tidak set',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Progres Pembangunan",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "${item.progressPercent}%",
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
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: item.progressPercent / 100,
                backgroundColor: AppColors.cardCream,
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Menu aksi ⋮ pada card proyek open ───
  Widget _buildProjectActionMenu(ProjectModel item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      onSelected: (value) async {
        if (value == 'edit') {
          await _handleEditProject(item);
        } else if (value == 'cancel') {
          await _handleCancelProject(item);
        }
      },
      itemBuilder: (_) {
        return [
          // Edit: hanya muncul jika belum ada bid sama sekali
          PopupMenuItem<String>(
            value: 'edit',
            child: FutureBuilder<int>(
              future: Provider.of<ProjectProvider>(context, listen: false)
                  .fetchProjectBidCountAll(item.id ?? ''),
              builder: (ctx, snap) {
                final bidCount = snap.data ?? 0;
                final canEdit = bidCount == 0;
                return Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18,
                        color: canEdit ? AppColors.primary : Colors.grey.shade400),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Proyek',
                      style: TextStyle(
                        color: canEdit ? Colors.black87 : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    if (!canEdit) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ada bid',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          // Batalkan: selalu muncul untuk proyek open
          const PopupMenuItem<String>(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Batalkan Proyek',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  // ─── Buka form edit ─────────────────────────────
  Future<void> _handleEditProject(ProjectModel item) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final bidCount = await provider.fetchProjectBidCountAll(item.id ?? '');
    if (!mounted) return;

    if (bidCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Proyek tidak bisa diedit karena sudah ada penawaran masuk.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Buka CreateProjectScreen dalam mode "edit proyek aktif"
    // Kita buat ProjectModel dengan status 'draft' agar form bisa menggunakannya
    // setelah disimpan, provider.updateProject dipanggil (bukan saveDraft).
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(
          draft: item.copyWith(status: 'open'),
          isEditMode: true,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  // ─── Dialog konfirmasi batalkan proyek ──────────
  Future<void> _handleCancelProject(ProjectModel item) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    // Cek apakah ada bid yang sudah accepted
    final hasAccepted = await provider.hasAcceptedBid(item.id ?? '');
    if (!mounted) return;

    if (hasAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Proyek tidak bisa dibatalkan karena penawaran sudah diterima.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bidCount =
        await provider.fetchProjectBidCountAll(item.id ?? '');
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Batalkan Proyek?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          bidCount > 0
              ? 'Proyek ini memiliki $bidCount penawaran masuk. Jika dibatalkan, semua kontraktor yang menawar akan melihat keterangan "Proyek Dibatalkan".\n\nLanjutkan?'
              : 'Proyek "${item.title}" akan dibatalkan. Tindakan ini tidak bisa diurungkan.',
          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child:
                const Text('Tidak', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Batalkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.cancelProject(item.id ?? '');
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Proyek berhasil dibatalkan.'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membatalkan proyek. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusTag(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'open':
        color = Colors.orange;
        label = 'OPEN';
        break;
      case 'in_progress':
        color = Colors.blue;
        label = 'BERJALAN';
        break;
      case 'completed':
        color = Colors.green;
        label = 'SELESAI';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'DIBATALKAN';
        break;
      case 'draft':
        color = Colors.grey;
        label = 'DRAFT';
        break;
      default:
        color = Colors.grey;
        label = status?.toUpperCase() ?? '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "Belum ada proyek nih.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}