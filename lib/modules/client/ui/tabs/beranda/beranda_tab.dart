import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:buildmatch/modules/client/ui/screens/create_project/create_project_screen.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/providers/notification_provider.dart';

// Bloc/Cubit logic
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/modules/client/ui/tabs/beranda/logic/beranda_cubit.dart';
import 'package:buildmatch/modules/client/ui/tabs/beranda/logic/beranda_state.dart';

// Extracted Widgets
import 'widgets/beranda_app_bar.dart';
import 'widgets/beranda_hero_card.dart';
import 'widgets/beranda_stats_row.dart';
import 'widgets/beranda_menu_grid.dart';
import 'widgets/beranda_top_partners.dart';
import 'widgets/beranda_my_projects.dart';

class BerandaTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const BerandaTab({super.key, this.onSwitchTab});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
        context.read<ChatCubit>().fetchChats();
      }
    });
  }

  Future<void> _refresh(BuildContext context) async {
    await context.read<BerandaCubit>().loadBerandaData();
  }

  // --- ACTIONS ---

  Future<void> _onMulaiProyek(BuildContext context) async {
    final provider = context.read<ProjectCubit>();
    final drafts = await provider.fetchDraftProjects();

    if (!mounted) return;

    if (drafts.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      ).then((val) {
        _refresh(context);
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(99);
        }
      });
      return;
    }

    final ProjectModel latestDraft = drafts.first;
    final String draftTitle =
        latestDraft.title.isNotEmpty && latestDraft.title != 'Draft Tanpa Judul'
        ? latestDraft.title
        : 'Draft Tanpa Judul';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ada Draft yang Belum Selesai',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kamu punya proyek yang belum dipublikasikan:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      draftTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (drafts.length > 1) ...[
              const SizedBox(height: 6),
              Text(
                '+ ${drafts.length - 1} draft lainnya di tab Progress',
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'new'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Buat Baru',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Lanjutkan Draft',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'continue') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProjectScreen(draft: latestDraft),
        ),
      ).then((val) {
        _refresh(context);
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(99);
        }
      });
    } else if (result == 'new') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      ).then((val) {
        _refresh(context);
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(99);
        }
      });
    }
  }

  void _goToContractorTab() => widget.onSwitchTab?.call(1);
  void _goToProgressTab() => widget.onSwitchTab?.call(3);

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BerandaCubit>(
      create: (context) => BerandaCubit(
        projectCubit: context.read<ProjectCubit>(),
        vendorCubit: context.read<VendorCubit>(),
      )..loadBerandaData(),
      child: Builder(
        builder: (scaffoldContext) {
          return Scaffold(
            backgroundColor: AppColors.backgroundCream,
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _refresh(scaffoldContext),
                child: BlocBuilder<BerandaCubit, BerandaState>(
                  builder: (context, state) {
                    if (state is BerandaInitial || state is BerandaLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (state is BerandaError) {
                      return Center(
                        child: Text(
                          'Gagal memuat data: ${state.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (state is BerandaLoaded) {
                      final projects = state.projects;
                      final topVendors = state.topVendors;
                      final incomingBids = state.incomingBids;
                      final profile = state.profile;

                      final activeProjects = projects
                          .where((p) => p.status == 'in_progress')
                          .toList();
                      final openProjects = projects
                          .where((p) => p.status == 'open')
                          .toList();

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BerandaAppBar(
                              profile: profile,
                              onSwitchTab: widget.onSwitchTab,
                            ),
                            const SizedBox(height: 20),
                            BerandaHeroCard(
                              profile: profile,
                              onMulaiProyek: () => _onMulaiProyek(scaffoldContext),
                            ),
                            const SizedBox(height: 24),
                            BerandaStatsRow(
                              activeCount: activeProjects.length,
                              openCount: openProjects.length,
                              bidsCount: incomingBids.length,
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader('Menu Utama'),
                            const SizedBox(height: 12),
                            BerandaMenuGrid(
                              onMulaiProyek: () => _onMulaiProyek(scaffoldContext),
                              onCariKontraktor: _goToContractorTab,
                              onCariArsitek: () => widget.onSwitchTab?.call(99),
                              onLihatProgress: _goToProgressTab,
                            ),
                            const SizedBox(height: 28),
                            _buildSectionHeader(
                              'Mitra Terpopuler',
                              onTap: () => widget.onSwitchTab?.call(1),
                            ),
                            const SizedBox(height: 12),
                            BerandaTopPartners(partners: topVendors),
                            const SizedBox(height: 28),
                            _buildSectionHeader('Proyek Saya', onTap: _goToProgressTab),
                            const SizedBox(height: 12),
                            BerandaMyProjects(
                              projects: [...activeProjects, ...openProjects],
                              onMulaiProyek: () => _onMulaiProyek(scaffoldContext),
                              onRefresh: () => _refresh(scaffoldContext),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- SECTION HEADER ---

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
