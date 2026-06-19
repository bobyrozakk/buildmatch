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

  void _onMulaiProyek() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
    ).then((_) => _refresh());
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPembangunanTab(List<ProjectModel> projects, List<BidModel> incomingBids) {
    if (projects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.engineering_outlined,
        title: 'Belum ada proyek pembangunan',
        subtitle: 'Buat proyek baru untuk mendapatkan penawaran dari kontraktor terbaik kami.',
        actionLabel: 'Buat Proyek Baru',
        onAction: _onMulaiProyek,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: projects.length,
      itemBuilder: (context, i) {
        final item = projects[i];

        if (item.status == 'open') {
          final projectBids = incomingBids.where((b) => b.projectId == item.id).toList();
          if (projectBids.isNotEmpty) {
            return ProgressGroupedBidCard(
              projectBids: projectBids,
              project: item,
              onRefresh: _refresh,
            );
          }
        }

        return ProgressProjectCard(
          project: item,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: item)),
          ).then((_) => _refresh()),
          onEdit: () => _handleEditProject(item),
          onCancel: () => _handleCancelProject(item),
          onDelete: () => _handleDeleteProject(item),
        );
      },
    );
  }

  Widget _buildDesainTab(List<BidModel> architectBids) {
    if (architectBids.isEmpty) {
      return _buildEmptyState(
        icon: Icons.architecture_rounded,
        title: 'Belum ada konsultasi desain',
        subtitle: 'Temukan arsitek terbaik di menu Mitra dan kirimkan ajakan konsultasi.',
        actionLabel: 'Cari Arsitek',
        onAction: () => widget.onSwitchTab?.call(1),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: architectBids.length,
      itemBuilder: (context, i) {
        final bid = architectBids[i];
        return ProgressArchitectBidCard(
          bid: bid,
          onRefresh: _refresh,
        );
      },
    );
  }

  Widget _buildDraftTab(List<ProjectModel> drafts) {
    if (drafts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'Belum ada draft proyek',
        subtitle: 'Proyek yang Anda simpan sebagai draft akan muncul di sini untuk dilanjutkan.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: drafts.length,
      itemBuilder: (context, i) {
        final draft = drafts[i];
        return ProgressDraftCard(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Proyek Saya",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _refresh,
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black45,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Pembangunan'),
              Tab(text: 'Desain'),
              Tab(text: 'Draft'),
            ],
          ),
        ),
        body: BlocBuilder<ProjectCubit, ProjectState>(
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

              return TabBarView(
                children: [
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _refresh(),
                    child: _buildPembangunanTab(projects, incomingBids),
                  ),
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _refresh(),
                    child: _buildDesainTab(architectBids),
                  ),
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _refresh(),
                    child: _buildDraftTab(drafts),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
