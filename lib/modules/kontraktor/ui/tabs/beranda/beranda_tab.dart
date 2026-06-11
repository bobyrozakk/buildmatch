// lib/modules/kontraktor/ui/tabs/beranda/beranda_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_state.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/profile_edit/profile_edit_screen.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/detail_proyek/detail_proyek_screen.dart';
import 'package:buildmatch/ui/shared/screens/chat_list_screen.dart';
import 'package:buildmatch/ui/shared/screens/notification_screen.dart';

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
    _loadData();
  }

  void _loadData() {
    final vendor = context.read<VendorCubit>();
    final project = context.read<ContractorProjectCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatCubit>().fetchChats();
      }
    });

    vendor.fetchVendorProfile();
    project.fetchAvailableProjects();
    project.fetchVendorActiveProjects();
    project.fetchVendorBids(status: 'pending');
    vendor.fetchReviews(userId);
  }

  Future<void> _refresh() async {
    final vendor = context.read<VendorCubit>();
    final project = context.read<ContractorProjectCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    
    await Future.wait([
      vendor.fetchVendorProfile(),
      project.fetchAvailableProjects(),
      project.fetchVendorActiveProjects(),
      project.fetchVendorBids(status: 'pending'),
      vendor.fetchReviews(userId),
    ]);
  }

  // --- ACTIONS ---

  Future<void> _openEditProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    _loadData();
  }

  void _openProjectDetail(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailProyekScreen(project: project)),
    );
  }

  void _goToProyekTab() {
    widget.onSwitchTab?.call(1);
  }

  void _goToProgressTab() {
    widget.onSwitchTab?.call(3);
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: BlocBuilder<VendorCubit, VendorState>(
            builder: (context, vendorState) {
              return BlocBuilder<ContractorProjectCubit, ContractorProjectState>(
                builder: (context, projectState) {
                  if (vendorState is VendorLoading ||
                      vendorState is VendorInitial ||
                      projectState is ContractorProjectLoading ||
                      projectState is ContractorProjectInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  ProfileModel? profile;
                  List<Map<String, dynamic>> reviews = [];
                  if (vendorState is VendorLoaded) {
                    profile = vendorState.vendorProfile;
                    reviews = vendorState.reviews;
                  }

                  List<ProjectModel> tenders = [];
                  List<ProjectModel> activeProjects = [];
                  List<BidModel> submittedBids = [];
                  if (projectState is ContractorProjectLoaded) {
                    tenders = projectState.availableProjects;
                    activeProjects = projectState.activeProjects;
                    submittedBids = projectState.myBids;
                  }

                  double avgRating = 0.0;
                  if (reviews.isNotEmpty) {
                    final totalRating = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num? ?? 0.0));
                    avgRating = totalRating / reviews.length;
                  }
                  final ratingStr = reviews.isEmpty ? '0.0' : avgRating.toStringAsFixed(1);

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
                        _buildStatsRow(activeProjects, ratingStr),
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
        BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final unreadCount = state is ChatLoaded ? state.totalUnreadCount : 0;
            return _buildIconBtn(
              Icons.chat_bubble_outline_rounded, 
              badge: unreadCount,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
              }
            );
          },
        ),
        const SizedBox(width: 8),
        _buildIconBtn(
          Icons.notifications_none_rounded, 
          badge: 0,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          }
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

  Widget _buildStatsRow(List<ProjectModel> activeProjects, String ratingStr) {
    final activeCount = activeProjects.where((p) => p.status == 'in_progress').length;
    final completedCount = activeProjects.where((p) => p.status == 'completed').length;

    return Row(
      children: [
        _buildStatItem('$activeCount', 'Proyek Aktif'),
        const SizedBox(width: 10),
        _buildStatItem('$completedCount', 'Selesai'),
        const SizedBox(width: 10),
        _buildStatItem('Rp 0', 'Pendapatan'),
        const SizedBox(width: 10),
        _buildStatItemWithIcon(ratingStr, 'Rating', Icons.star_rounded),
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
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
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
                Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
                const SizedBox(width: 2),
                Icon(icon, color: Colors.amber, size: 14),
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
      height: 300,
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
                  if (p.imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p.imageUrls[0], height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))),
                    )
                  else
                    Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  const SizedBox(height: 8),
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
      height: 300,
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
                  if (p?.imageUrls.isNotEmpty == true)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p!.imageUrls[0], height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))),
                    )
                  else
                    Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Builder(builder: (context) {
                    final isRejected = b.status == 'rejected' || (b.status == 'pending' && b.createdAt != null && DateTime.now().difference(b.createdAt!).inDays > 7);
                    final statusLabel = isRejected ? 'Diabaikan' : 'Menunggu';
                    final statusColor = isRejected ? Colors.red : Colors.orange;
                    final statusIcon = isRejected ? Icons.cancel_outlined : Icons.access_time_rounded;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    );
                  }),
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
    final list = projects.where((p) => p.status == 'in_progress').take(3).toList();
    if (list.isEmpty) {
      return _buildEmptyCard('Belum ada proyek berjalan');
    }
    return Column(
      children: list.map((p) {
        final progress = (p.progressPercent / 100.0).clamp(0.0, 1.0);
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
                if (p.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(p.imageUrls[0], height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey))),
                  )
                else
                  Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                const SizedBox(height: 12),
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
