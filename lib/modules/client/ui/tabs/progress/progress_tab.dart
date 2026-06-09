import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/modules/client/ui/screens/create_project/create_project_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';
import 'widgets/progress_architect_bid_card.dart';
import 'widgets/progress_grouped_bid_card.dart';
import 'widgets/progress_draft_card.dart';
import 'widgets/progress_project_card.dart';
import 'widgets/progress_empty_state.dart';

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

  Future<void> _handleEditProject(ProjectModel item) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final bidCount = await provider.fetchProjectBidCountAll(item.id ?? '');
    if (!mounted) return;

    if (bidCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyek tidak bisa diedit karena sudah ada penawaran masuk.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

  Future<void> _handleCancelProject(ProjectModel item) async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final hasAccepted = await provider.hasAcceptedBid(item.id ?? '');
    if (!mounted) return;

    if (hasAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyek tidak bisa dibatalkan karena penawaran sudah diterima.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bidCount = await provider.fetchProjectBidCountAll(item.id ?? '');
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Batalkan Proyek?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Tidak', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
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
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.gavel_rounded, size: 16, color: Colors.orange),
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

                    ...grouped.entries.map((entry) {
                      final projectBids = entry.value;
                      final firstBid = projectBids.first;
                      final project = firstBid.project;
                      return ProgressGroupedBidCard(
                        projectBids: projectBids,
                        project: project,
                        onRefresh: _refresh,
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
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.architecture_rounded, size: 16, color: Colors.purple),
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

                    ...architectBids.map(
                      (bid) => ProgressArchitectBidCard(
                        bid: bid,
                        onRefresh: _refresh,
                      ),
                    ),

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
                    Row(
                      children: [
                        const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.primary),
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

                    ...drafts.map(
                      (draft) => ProgressDraftCard(
                        draft: draft,
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
                        onDelete: () => _confirmDeleteDraft(draft),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Divider(height: 32),

                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, size: 16, color: Colors.black54),
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
                  return const ProgressEmptyState();
                }

                final projects = snapshot.data!;
                return Column(
                  children: projects
                      .map(
                        (item) => ProgressProjectCard(
                          project: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: item)),
                          ).then((_) => _refresh()),
                          onEdit: () => _handleEditProject(item),
                          onCancel: () => _handleCancelProject(item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
