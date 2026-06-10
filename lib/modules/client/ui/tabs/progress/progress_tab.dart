import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/modules/client/ui/screens/create_project/create_project_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/client/logic/project/project_state.dart';
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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final cubit = context.read<ProjectCubit>();
    cubit.fetchProjects();
    cubit.fetchDraftProjects();
    cubit.fetchClientIncomingBids();
    cubit.fetchClientArchitectBids();
  }

  Future<void> _confirmDeleteDraft(ProjectModel draft) async {
    final cubit = context.read<ProjectCubit>();
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
      final success = await cubit.deleteDraft(draft.id!);
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
    final cubit = context.read<ProjectCubit>();
    final bidCount = await cubit.fetchProjectBidCountAll(item.id ?? '');
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
    final cubit = context.read<ProjectCubit>();

    final hasAccepted = await cubit.hasAcceptedBid(item.id ?? '');
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

    final bidCount = await cubit.fetchProjectBidCountAll(item.id ?? '');
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
      final success = await cubit.cancelProject(item.id ?? '');
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

  Future<void> _handleDeleteProject(ProjectModel item) async {
    final cubit = context.read<ProjectCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Proyek?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Proyek "${item.title}" akan dihapus permanen dari sistem.',
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

    if (confirmed == true && item.id != null) {
      final success = await cubit.deleteProject(item.id!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proyek berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _refresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus proyek'),
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
        child: BlocBuilder<ProjectCubit, ProjectState>(
          builder: (context, state) {
            if (state is ProjectInitial || state is ProjectLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is ProjectError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Gagal memuat data: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state is ProjectLoaded) {
              final projects = state.projects;
              final drafts = state.draftProjects;
              final incomingBids = state.incomingBids;
              final architectBids = state.architectBids;

              final List<Widget> listChildren = [];

              // ── SECTION PENAWARAN KONTRAKTOR MASUK (GROUPED PER PROYEK) ──
              if (incomingBids.isNotEmpty) {
                final Map<String, List<BidModel>> grouped = {};
                for (final bid in incomingBids) {
                  grouped.putIfAbsent(bid.projectId, () => []).add(bid);
                }

                listChildren.addAll([
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
                ]);
              }

              // ── SECTION KONSULTASI ARSITEK ──
              if (architectBids.isNotEmpty) {
                listChildren.addAll([
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
                ]);
              }

              // ── SECTION DRAFT ──
              if (drafts.isNotEmpty) {
                listChildren.addAll([
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
                ]);
              }

              // ── SECTION PROYEK AKTIF ──
              if (projects.isEmpty) {
                listChildren.add(const ProgressEmptyState());
              } else {
                listChildren.addAll(
                  projects.map(
                    (item) => ProgressProjectCard(
                      project: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: item)),
                      ).then((_) => _refresh()),
                      onEdit: () => _handleEditProject(item),
                      onCancel: () => _handleCancelProject(item),
                      onDelete: () => _handleDeleteProject(item),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: listChildren,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
