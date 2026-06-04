import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../shared/screens/notification_screen.dart';
import '../screens/edit_profil_screen.dart';
import '../screens/detail_desain_screen.dart';

class ArsitekHomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const ArsitekHomeTab({super.key, this.onSwitchTab});

  @override
  State<ArsitekHomeTab> createState() => _ArsitekHomeTabState();
}

class _ArsitekHomeTabState extends State<ArsitekHomeTab> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final architect = Provider.of<ArchitectProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";

    _dataFuture = Future.wait([
      architect.fetchArchitectDetails(userId), // 0: profile
      architect.fetchPortfolios(userId), // 1: own portfolios
      architect.fetchArchitectStats(userId), // 2: stats
      architect.fetchCollaborationRequests(), // 3: collab requests
      architect.fetchAllPortfolios(), // 4: all designs (unified)
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8F2A0C),
          onRefresh: _refresh,
          child: FutureBuilder<List<dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8F2A0C)),
                );
              }

              final profileData = snapshot.data?[0] as Map<String, dynamic>?;
              final stats = snapshot.data?[2] as Map<String, dynamic>? ?? {};
              final collabs =
                  snapshot.data?[3] as List<Map<String, dynamic>>? ?? [];
              final popularDesigns =
                  snapshot.data?[4] as List<Map<String, dynamic>>? ?? [];

              final profile = profileData?['profile'] as ProfileModel?;
              final name = _currentUserName(profile, fallback: 'Arsitek');
              double completionVal = 0.85; // Default for now

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
                    _buildWelcomeCard(name, completionVal),
                    const SizedBox(height: 24),
                    _buildStatsRow(stats),
                    const SizedBox(height: 28),
                    _buildPermintaanKolaborasi(),
                    const SizedBox(height: 28),
                    _buildDesainPopuler(popularDesigns),
                    const SizedBox(height: 100), // Spacing for bottom nav
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ProfileModel? profile) {
    final name = _currentUserName(profile, fallback: 'Arsitek');
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
          builder: (context, chat, child) => GestureDetector(
            onTap: () {
              widget.onSwitchTab?.call(2);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                if (chat.totalUnreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${chat.totalUnreadCount}',
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
          ),
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, notif, child) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                if (notif.unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${notif.unreadCount}',
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
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            _refresh();
          },
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.cardCream,
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String name, double completion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8F2A0C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat datang arsitek, ',
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
          const SizedBox(height: 12),
          const Text(
            'Profil Anda hampir selesai. Lengkapi\nuntuk menjangkau lebih banyak klien.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Kelengkapan Profil',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${(completion * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF59E0B),
              ), // Orange
            ),
          ),
        ],
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

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final activeCollabs = stats['active_collabs']?.toString() ?? '0';
    final totalDesigns = stats['portfolio_count']?.toString() ?? '0';
    final experience = stats['experience_years']?.toString() ?? '0';
    final certs = stats['cert_count']?.toString() ?? '0';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Kolaborasi Aktif',
          activeCollabs,
          Icons.people_alt_outlined,
        ),
        _buildStatCard(
          'Total Desain',
          totalDesigns,
          Icons.design_services_outlined,
        ),
        _buildStatCard('Tahun Pengalaman', experience, Icons.access_time),
        _buildStatCard('Sertifikasi', certs, Icons.workspace_premium_outlined),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    bool isStar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3EBE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isStar
                    ? const Color(0xFFD97706)
                    : const Color(0xFF8F2A0C),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermintaanKolaborasi() {
    return Consumer<ChatProvider>(
      builder: (context, chatProv, child) {
        final pendingChats = chatProv.pendingChats;
        if (pendingChats.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Permintaan Kolaborasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      widget.onSwitchTab?.call(2), // Assume tab 2 is inbox/requests
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F2A0C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 165,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                children: pendingChats.map((chat) {
                  final clientName = chat.clientName ?? 'Client';
                  final clientAvatar = chat.clientAvatar ??
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(clientName)}&background=B53D1B&color=fff';
                  final lastMsg = chat.lastMessage ?? 'Ingin berkonsultasi dengan Anda';

                  return _buildCollabCard(
                    clientName,
                    'Client',
                    lastMsg,
                    clientAvatar,
                    onAccept: () async {
                      final ok = await chatProv.acceptChat(chat.id);
                      if (ok && mounted) {
                        widget.onSwitchTab?.call(2);
                      }
                    },
                    onDetail: () {
                      widget.onSwitchTab?.call(2);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollabCard(
    String name,
    String role,
    String quote,
    String imgUrl, {
    VoidCallback? onAccept,
    VoidCallback? onDetail,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3EBE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(imgUrl),
                backgroundColor: const Color(0xFFF3EBE3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      role,
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
          const SizedBox(height: 12),
          Text(
            quote,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: onAccept ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1C08), // Dark brown
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Terima',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onDetail ?? () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Detail',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesainPopuler(List<Map<String, dynamic>> popularDesigns) {
    if (popularDesigns.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show at most 4 items menyamping
    final displayList = popularDesigns.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Desain Populer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            GestureDetector(
              onTap: () => widget.onSwitchTab?.call(1),
              child: const Text(
                'Lihat Galeri',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8F2A0C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: displayList.length,
            itemBuilder: (context, i) {
              final item = displayList[i];
              final title = item['title'] ?? "";
              final style = item['style'] ?? "Modern";
              final imgUrl = item['image_url'] ?? "";
              final architectName = item['architect_name'] ?? "Arsitek";
              final rating = (item['avg_rating'] as num?) ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailDesainScreen(designData: item),
                    ),
                  );
                },
                child: Container(
                  width: 220,
                  margin: EdgeInsets.only(right: i < displayList.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imgUrl.toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgUrl.toString().startsWith('http')
                            ? Image.network(imgUrl, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)))
                            : Container(height: 100, width: double.infinity, color: AppColors.cardCream),
                        )
                      else
                        Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(style, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              architectName,
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toDouble().toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            )
                          else
                            const SizedBox(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Lihat Detail', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
