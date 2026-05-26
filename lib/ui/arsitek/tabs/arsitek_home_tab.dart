import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/screens/notification_screen.dart';
import '../screens/edit_profil_screen.dart';

class ArsitekHomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const ArsitekHomeTab({super.key, this.onSwitchTab});

  @override
  State<ArsitekHomeTab> createState() => _ArsitekHomeTabState();
}

class _ArsitekHomeTabState extends State<ArsitekHomeTab> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final architect = Provider.of<ArchitectProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    _profileFuture = architect.fetchArchitectDetails(userId);
    _portfolioFuture = architect.fetchPortfolios(userId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await Future.wait([_profileFuture, _portfolioFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8F2A0C),
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8F2A0C)));
              }

              final profileData = profileSnapshot.data;
              final profile = profileData?['profile'] as ProfileModel?;
              final rawBio = profileData?['bio'] as String? ?? "";
              final specs = profileData?['specializations'] as Map<String, dynamic>? ?? {};
              
              final name = profile?.name.isNotEmpty == true ? profile!.name : "Arsitek";
              
              double completionVal = 0.85; // Using 85% as in Figma

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _portfolioFuture,
                builder: (context, portoSnapshot) {
                  final listPorto = portoSnapshot.data ?? [];
                  
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(profile),
                        const SizedBox(height: 20),
                        _buildWelcomeCard(name, completionVal),
                        const SizedBox(height: 24),
                        _buildStatsRow(),
                        const SizedBox(height: 28),
                        _buildPermintaanKolaborasi(),
                        const SizedBox(height: 28),
                        _buildDesainPopuler(listPorto),
                        const SizedBox(height: 100), // Spacing for bottom nav
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ProfileModel? profile) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        const Text(
          'BuildMatch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF8F2A0C)),
        ),
        const Spacer(),
        Consumer<NotificationProvider>(
          builder: (context, notif, child) => GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF8F2A0C), size: 24),
                if (notif.unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            _refresh();
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF3EBE3),
            backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : const NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg'),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String name, double completion) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
        _refresh();
      },
      child: Container(
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
              'Halo, Arsitek Andi!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Profil Anda hampir selesai. Lengkapi\nuntuk menjangkau lebih banyak klien.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Kelengkapan Profil', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                Text('${(completion * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)), // Orange
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Kolaborasi Aktif', '12', Icons.people_alt_outlined),
        _buildStatCard('Total Desain', '48', Icons.design_services_outlined),
        _buildStatCard('Rating Klien', '4.9/5.0', Icons.star, isStar: true),
        _buildStatCard('Desain Disimpan', '156', Icons.bookmark_outline),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool isStar = false}) {
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
              Icon(icon, color: isStar ? const Color(0xFFD97706) : const Color(0xFF8F2A0C), size: 16),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPermintaanKolaborasi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Permintaan Kolaborasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            GestureDetector(
              onTap: () => widget.onSwitchTab?.call(2),
              child: const Text('Lihat Semua', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 165, // Adjust height for the buttons inside the card
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              _buildCollabCard(
                'Budi Santoso',
                'Kontraktor Utama',
                '"Tertarik untuk kolaborasi pada proyek perumahan minimalis di..."',
                'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg',
              ),
              _buildCollabCard(
                'Siti Aminah',
                'Client',
                '"Butuh desain untuk proyek villa tropis modern di area pantai..."',
                'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollabCard(String name, String role, String quote, String imgUrl) {
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
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Text(role, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1C08), // Dark brown
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Terima', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black87),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Detail', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesainPopuler(List<Map<String, dynamic>> portoList) {
    // Mock data based on Figma screenshot
    final List<Map<String, dynamic>> displayList = [
      {
        'title': 'Villa Tepi Pantai',
        'likes': '2.4k',
        'image_url': 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/modern_villa.jpg',
      },
      {
        'title': 'Kantor Industrial',
        'likes': '1.8k',
        'image_url': 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=500&q=80',
      },
      {
        'title': 'Teras Terracotta',
        'likes': '3.1k',
        'image_url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
      },
      {
        'title': 'Eco-Smart Home',
        'likes': '1.2k',
        'image_url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=500&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Desain Populer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            GestureDetector(
              onTap: () => widget.onSwitchTab?.call(1),
              child: const Text('Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, i) {
            final item = displayList[i];
            final title = item['title'] ?? "";
            final likes = item['likes'] ?? "0";
            final imgUrl = item['image_url'] ?? "";

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3EBE3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.network(imgUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_rounded, size: 10, color: Color(0xFFD97706)), // Orange thumb
                            const SizedBox(width: 4),
                            Text(likes, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
