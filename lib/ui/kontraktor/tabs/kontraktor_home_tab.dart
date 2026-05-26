import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/bid_model.dart';
import '../../../data/providers/vendor_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../screens/kontraktor_profileEdit_screen.dart';
import '../screens/kontraktor_detail_proyek_screen.dart';
import '../../shared/screens/chat_list_screen.dart';
import '../../shared/screens/notification_screen.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/notification_provider.dart';

class KontraktorHomeTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const KontraktorHomeTab({super.key, this.onSwitchTab});

  @override
  State<KontraktorHomeTab> createState() => _KontraktorHomeTabState();
}

class _KontraktorHomeTabState extends State<KontraktorHomeTab> {
  late Future<List<dynamic>> _dataFuture;
  final List<_NotifItem> _notifications = [
    _NotifItem(Icons.mail_outline_rounded, 'Penawaran baru masuk untuk Proyek Renovasi Minimalis', '2 menit yang lalu', AppColors.primary),
    _NotifItem(Icons.chat_bubble_outline_rounded, 'Pesan baru dari Klien Agus Prasetyo', '30 menit yang lalu', AppColors.primary),
    _NotifItem(Icons.warning_amber_rounded, 'Ingat: Update progres Proyek Villa Tropis Bali', '1 jam yang lalu', Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final vendor = Provider.of<VendorProvider>(context, listen: false);
    final project = Provider.of<ProjectProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
      }
    });

    _dataFuture = Future.wait([
      vendor.fetchVendorProfile(),
      project.fetchAvailableProjects(),
      project.fetchVendorActiveProjects(),
      project.fetchVendorBids(status: 'pending'),
    ]);
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await _dataFuture;
  }

  // --- ACTIONS ---

  Future<void> _openEditProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    setState(_loadData);
  }

  void _openProjectDetail(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KontraktorDetailProyekScreen(project: project)),
    );
  }

  void _goToProyekTab() {
    widget.onSwitchTab?.call(1);
  }

  void _goToProgressTab() {
    widget.onSwitchTab?.call(3);
  }

  // Removed dummy _showNotifSheet, we use NotificationScreen now.


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
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final profile = snapshot.data?[0] as ProfileModel?;
              final tenders = (snapshot.data?[1] as List<ProjectModel>? ?? []);
              final activeProjects = (snapshot.data?[2] as List<ProjectModel>? ?? []);
              final submittedBids = (snapshot.data?[3] as List<BidModel>? ?? []);

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(profile),
                    const SizedBox(height: 20),
                    _buildWelcomeCard(profile),
                    const SizedBox(height: 24),
                    _buildStatsRow(activeProjects.length),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Penawaran Masuk', onTap: _goToProyekTab),
                    const SizedBox(height: 12),
                    _buildPenawaranList(tenders),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Penawaran Diajukan', onTap: _goToProyekTab),
                    const SizedBox(height: 12),
                    _buildPenawaranDiajukanList(submittedBids),
                    const SizedBox(height: 28),
                    _buildSectionHeader('Proyek Berjalan', onTap: _goToProgressTab),
                    const SizedBox(height: 12),
                    _buildProyekBerjalan(activeProjects),
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

  // --- APP BAR (ORIGINAL LOGO) ---

  Widget _buildAppBar(ProfileModel? profile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.hardware_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'Build', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            TextSpan(text: 'Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          ]),
        ),
        const Spacer(),
        Consumer<ChatProvider>(
          builder: (context, chat, child) => _buildIconBtn(
            Icons.chat_bubble_outline_rounded, 
            badge: chat.totalUnreadCount,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            }
          ),
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, notif, child) => _buildIconBtn(
            Icons.notifications_none_rounded, 
            badge: notif.unreadCount,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            }
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _openEditProfile,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.cardCream,
            backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
            child: profile?.avatarUrl == null
                ? const Icon(Icons.person, size: 20, color: AppColors.primary)
                : null,
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
            decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badge',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WELCOME CARD ---

  Widget _buildWelcomeCard(ProfileModel? profile) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.userMetadata?['name'] ?? 'Kontraktor');
    final company = profile?.companyName ?? 'Vendor BuildMatch';
    final completion = _profileCompletion(profile);

    return GestureDetector(
      onTap: _openEditProfile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(company, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                if (profile?.isVerified == true) ...[
                  const Icon(Icons.verified, color: Colors.white, size: 14),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Profil ${(completion * 100).toInt()}% lengkap', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('${(completion * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lengkapi Sekarang', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _profileCompletion(ProfileModel? p) {
    if (p == null) return 0.0;
    int filled = 0;
    const total = 6;
    if (p.name.isNotEmpty) filled++;
    if (p.companyName?.isNotEmpty == true) filled++;
    if (p.phone?.isNotEmpty == true) filled++;
    if (p.npwp?.isNotEmpty == true) filled++;
    if (p.straNumber?.isNotEmpty == true) filled++;
    if (p.avatarUrl?.isNotEmpty == true) filled++;
    return filled / total;
  }

  // --- STATS ---

  Widget _buildStatsRow(int activeCount) {
    return Row(
      children: [
        _buildStatItem('$activeCount', 'Proyek Aktif'),
        const SizedBox(width: 10),
        _buildStatItem('12', 'Selesai'),
        const SizedBox(width: 10),
        _buildStatItem('45jt', 'Pendapatan'),
        const SizedBox(width: 10),
        _buildStatItemWithIcon('4.9', 'Rating', Icons.star_rounded),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWithIcon(String val, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
                const SizedBox(width: 2),
                Icon(icon, color: Colors.amber, size: 16),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ],
    );
  }

  // --- PENAWARAN MASUK ---

  Widget _buildPenawaranList(List<ProjectModel> tenders) {
    if (tenders.isEmpty) {
      return _buildEmptyCard('Belum ada penawaran masuk');
    }
    final list = tenders.take(5).toList();
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];
          return GestureDetector(
            onTap: () => _openProjectDetail(p),
            child: Container(
              width: 220,
              margin: EdgeInsets.only(right: i < list.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Baru', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 8),
                  Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _infoRow(Icons.person_outline, p.clientName ?? 'Klien'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.location_on_outlined, p.location ?? 'Lokasi tidak diketahui'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.monetization_on_outlined, AppFormatters.formatRupiah(p.budget), color: AppColors.primary, bold: true),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_timeAgo(p.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black38)),
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
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color, bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color ?? Colors.black54),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color ?? Colors.black54, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- PENAWARAN DIAJUKAN ---

  Widget _buildPenawaranDiajukanList(List<BidModel> bids) {
    if (bids.isEmpty) {
      return _buildEmptyCard('Belum ada penawaran diajukan');
    }
    final list = bids.take(5).toList();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          final p = b.project;
          return GestureDetector(
            onTap: p == null ? null : () => _openProjectDetail(p),
            child: Container(
              width: 220,
              margin: EdgeInsets.only(right: i < list.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Menunggu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p?.title ?? 'Proyek tidak tersedia',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _infoRow(Icons.person_outline, p?.clientName ?? 'Klien'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.location_on_outlined, p?.location ?? '-'),
                  const SizedBox(height: 3),
                  _infoRow(Icons.monetization_on_outlined, AppFormatters.formatRupiah(b.price), color: AppColors.primary, bold: true),
                  const Spacer(),
                  Text(_timeAgo(b.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black38)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- PROYEK BERJALAN ---

  Widget _buildProyekBerjalan(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return _buildEmptyCard('Belum ada proyek berjalan');
    }
    final list = projects.take(3).toList();
    return Column(
      children: list.map((p) {
        final progress = (p.progressPercent / 100).clamp(0.0, 1.0);
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
                    Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        _formatDate(p.createdAt),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 13, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(p.clientName ?? 'Klien', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progres', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('${p.progressPercent}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
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
        child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari yang lalu';
    return _formatDate(date);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _NotifItem {
  final IconData icon;
  final String text;
  final String time;
  final Color color;
  _NotifItem(this.icon, this.text, this.time, this.color);
}
