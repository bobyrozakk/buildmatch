import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:buildmatch/modules/client/ui/screens/create_project/create_project_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/project_detail/project_detail_screen.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
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

  void _openProjectDetail(ProjectModel p, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)),
    ).then((_) => _refresh(context));
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
                              'Kontraktor Terpopuler',
                              onTap: _goToContractorTab,
                            ),
                            const SizedBox(height: 12),
                            _buildKontraktorList(topVendors),
                            const SizedBox(height: 28),
                            _buildSectionHeader('Proyek Saya', onTap: _goToProgressTab),
                            const SizedBox(height: 12),
                            _buildProyekSaya(
                              [...activeProjects, ...openProjects],
                              scaffoldContext,
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

  // --- KONTRAKTOR TERPOPULER ---

  Widget _buildKontraktorList(List<Map<String, dynamic>> vendors) {
    if (vendors.isEmpty) {
      return _buildEmptyCard('Belum ada data rating kontraktor');
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        itemBuilder: (_, i) {
          final item = vendors[i];
          final profile = item['profile'] as ProfileModel;
          final avgRating = item['avgRating'] as double;
          final reviewCount = item['reviewCount'] as int;
          final displayName = profile.companyName?.isNotEmpty == true
              ? profile.companyName!
              : profile.name;

          return Container(
            width: 170,
            margin: EdgeInsets.only(right: i < vendors.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.cardCream,
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.name)}&background=B53D1B&color=fff&size=128',
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 11,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (profile.isVerified)
                      const Icon(Icons.verified, color: Colors.blue, size: 13),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$reviewCount ulasan',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${avgRating.toStringAsFixed(1)} • $reviewCount review',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- PROYEK SAYA (open + in_progress) ---

  Widget _buildProyekSaya(List<ProjectModel> projects, BuildContext context) {
    if (projects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada proyek',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buat proyek pertamamu untuk mulai\nmendapatkan penawaran kontraktor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.black38,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _onMulaiProyek(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Buat Proyek',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final list = projects.take(3).toList();
    return Column(
      children: list.map((p) {
        final isActive = p.status == 'in_progress';
        final progress = (p.progressPercent / 100).clamp(0.0, 1.0);

        // Status badge config
        final String statusLabel;
        final Color statusColor;
        if (p.status == 'in_progress') {
          statusLabel = 'BERJALAN';
          statusColor = Colors.blue;
        } else if (p.status == 'open') {
          statusLabel = 'OPEN TENDER';
          statusColor = Colors.orange;
        } else {
          statusLabel = (p.status ?? 'N/A').toUpperCase();
          statusColor = Colors.grey;
        }

        return GestureDetector(
          onTap: () => _openProjectDetail(p, context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.location ?? 'Lokasi tidak diketahui',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormatters.formatRupiah(p.budget),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progres',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        '${p.progressPercent}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- HELPERS ---

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
