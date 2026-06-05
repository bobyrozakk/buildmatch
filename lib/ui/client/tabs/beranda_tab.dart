import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/create_project_screen.dart';
import '../screens/project_detail_screen.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/providers/vendor_provider.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/bid_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

import '../../shared/screens/notification_screen.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/notification_provider.dart';

class BerandaTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const BerandaTab({super.key, this.onSwitchTab});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final project = Provider.of<ProjectProvider>(context, listen: false);
    final vendor = Provider.of<VendorProvider>(context, listen: false);

    // Fetch notifications and chats in background after initial build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
      }
    });

    _dataFuture = Future.wait([
      project.fetchProjects(), // 0: client projects (non-draft)
      vendor.fetchTopVendors(), // 1: top rated vendors
      project.fetchClientIncomingBids(), // 2: incoming bids
      _fetchCurrentProfile(), // 3: current client profile
    ]);
  }

  Future<ProfileModel?> _fetchCurrentProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response == null ? null : ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetch current client profile: $e');
      return null;
    }
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await _dataFuture;
  }

  // --- ACTIONS ---

  Future<void> _onMulaiProyek() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final drafts = await provider.fetchDraftProjects();

    if (!mounted) return;

    if (drafts.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      ).then((val) {
        _refresh();
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(2);
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
        _refresh();
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(2);
        }
      });
    } else if (result == 'new') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      ).then((val) {
        _refresh();
        if (val == 'route_to_consultation') {
          widget.onSwitchTab?.call(2);
        }
      });
    }
  }

  void _openProjectDetail(ProjectModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)),
    ).then((_) => _refresh());
  }

  void _goToContractorTab() => widget.onSwitchTab?.call(1);
  void _goToProgressTab() => widget.onSwitchTab?.call(3);

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: FutureBuilder<List<dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final projects = (snapshot.data?[0] as List<ProjectModel>? ?? []);
              final topVendors =
                  (snapshot.data?[1] as List<Map<String, dynamic>>? ?? []);
              final incomingBids = (snapshot.data?[2] as List<BidModel>? ?? []);
              final profile = snapshot.data?[3] as ProfileModel?;

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
                    _buildAppBar(profile),
                    const SizedBox(height: 20),
                    _buildHeroCard(profile),
                    const SizedBox(height: 24),
                    _buildStatsRow(
                      activeCount: activeProjects.length,
                      openCount: openProjects.length,
                      bidsCount: incomingBids.length,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Menu Utama'),
                    const SizedBox(height: 12),
                    _buildMenuGrid(),
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
                    _buildProyekSaya([...activeProjects, ...openProjects]),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- APP BAR ---

  Widget _buildAppBar(ProfileModel? profile) {
    final name = _currentUserName(profile, fallback: 'Klien');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.hardware_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Build',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Consumer<ChatProvider>(
          builder: (context, chat, child) => _buildIconBtn(
            Icons.chat_bubble_outline_rounded,
            badge: chat.totalUnreadCount,
            onTap: () {
              widget.onSwitchTab?.call(2);
            },
          ),
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, notif, child) => _buildIconBtn(
            Icons.notifications_none_rounded,
            badge: notif.unreadCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.cardCream,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'K',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, {VoidCallback? onTap, int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- HERO CARD ---

  Widget _buildHeroCard(ProfileModel? profile) {
    final name = _currentUserName(profile, fallback: 'Klien');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat datang,',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bangun rumah impianmu mulai dari sini. Buat proyek, dapatkan penawaran terbaik dari kontraktor.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _onMulaiProyek,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mulai Proyek',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  // --- STATS ---

  Widget _buildStatsRow({
    required int activeCount,
    required int openCount,
    required int bidsCount,
  }) {
    return Row(
      children: [
        _buildStatItem('$activeCount', 'Proyek Aktif'),
        const SizedBox(width: 10),
        _buildStatItem('$openCount', 'Open\nTender'),
        const SizedBox(width: 10),
        _buildStatItem('$bidsCount', 'Penawaran\nMasuk'),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  // --- MENU UTAMA (4 items - fitur nyata) ---

  Widget _buildMenuGrid() {
    final menuItems = [
      _MenuItem(
        Icons.add_circle_outline_rounded,
        'Buat Proyek',
        _onMulaiProyek,
      ),
      _MenuItem(
        Icons.engineering_rounded,
        'Cari Kontraktor',
        _goToContractorTab,
      ),
      _MenuItem(
        Icons.architecture_outlined,
        'Cari Arsitek',
        () => widget.onSwitchTab?.call(2),
      ),
      _MenuItem(Icons.timeline_rounded, 'Lihat Progress', _goToProgressTab),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: menuItems.map((item) {
        return GestureDetector(
          onTap: item.onTap,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

  Widget _buildProyekSaya(List<ProjectModel> projects) {
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
              onTap: _onMulaiProyek,
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
          onTap: () => _openProjectDetail(p),
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

  String _currentUserName(ProfileModel? profile, {required String fallback}) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileName = profile?.name.trim();
    final metadataName = user?.userMetadata?['name']?.toString().trim();

    if (profileName != null && profileName.isNotEmpty) return profileName;
    if (metadataName != null && metadataName.isNotEmpty) return metadataName;
    return fallback;
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  _MenuItem(this.icon, this.label, this.onTap);
}
