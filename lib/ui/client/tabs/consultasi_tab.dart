import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/architect_provider.dart';
import '../../shared/screens/chat_detail_screen.dart';
import '../screens/architect_detail_screen.dart';

class ConsultasiTab extends StatefulWidget {
  const ConsultasiTab({super.key});

  @override
  State<ConsultasiTab> createState() => _ConsultasiTabState();
}

class _ConsultasiTabState extends State<ConsultasiTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _initFuture;
  late Future<List<Map<String, dynamic>>> _architectsFuture;

  final _searchInboxController = TextEditingController();
  final _searchArchitectController = TextEditingController();
  String _searchInbox = '';
  String _searchArchitect = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initFuture =
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
    _architectsFuture =
        Provider.of<ArchitectProvider>(context, listen: false).fetchAllArchitects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchInboxController.dispose();
    _searchArchitectController.dispose();
    super.dispose();
  }

  /// Ubah konten pesan terakhir menjadi teks yang ramah pengguna
  String _formatLastMessage(String? content) {
    if (content == null || content.isEmpty) return 'Belum ada pesan';

    // Deteksi JSON (penawaran atau desain)
    if (content.startsWith('{')) {
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'offer') {
          return '📋 Penawaran desain dikirim';
        } else if (type == 'design') {
          final rev = data['revision_number'] as int? ?? 1;
          return '🎨 Desain revisi ke-$rev dikirimkan';
        }
      } catch (_) {}
    }

    // Deteksi URL Supabase / lampiran
    if (content.startsWith('http://') || content.startsWith('https://')) {
      final lower = content.toLowerCase();
      final isImage = lower.contains('.png') ||
          lower.contains('.jpg') ||
          lower.contains('.jpeg') ||
          lower.contains('.gif') ||
          lower.contains('.webp');
      if (isImage) return '🖼️ Gambar dilampirkan';
      return '📎 File dilampirkan';
    }

    return content;
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(dt.toLocal());
    if (diff.inDays == 1) return 'Kemarin';
    return DateFormat('d MMM', 'id').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Konsultasi',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87),
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (_, chatProv, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.black54, size: 24),
                  onPressed: () {},
                ),
                if (chatProv.totalUnreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black45,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Arsitek'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(),
          _buildArsitekTab(),
        ],
      ),
    );
  }

  // ==================== TAB INBOX ====================

  Widget _buildInboxTab() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      children: [
        _buildSearchBar(
          controller: _searchInboxController,
          hint: 'Cari percakapan...',
          onChanged: (v) => setState(() => _searchInbox = v),
        ),
        Expanded(
          child: FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              return Consumer<ChatProvider>(
                builder: (_, chatProv, __) {
                  // Client sees both accepted and pending chats in the Inbox list
                  final allChats = [...chatProv.chats, ...chatProv.pendingChats];
                  allChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  var chats = allChats;

                  if (_searchInbox.isNotEmpty) {
                    final q = _searchInbox.toLowerCase();
                    chats = chats.where((c) {
                      final name = (currentUserId == c.clientId
                              ? c.vendorName
                              : c.clientName) ??
                          '';
                      return name.toLowerCase().contains(q);
                    }).toList();
                  }

                  if (chats.isEmpty) {
                    return _buildInboxEmpty();
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => chatProv.fetchChats(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: chats.length,
                      itemBuilder: (_, i) {
                        final chat = chats[i];
                        final isClientSide = currentUserId == chat.clientId;
                        final displayName = isClientSide
                            ? (chat.vendorName ?? 'Arsitek')
                            : (chat.clientName ?? 'Klien');
                        final displayAvatar = isClientSide
                            ? chat.vendorAvatar
                            : chat.clientAvatar;
                        return _buildChatTile(
                          chat: chat,
                          displayName: displayName,
                          displayAvatar: displayAvatar,
                          chatProv: chatProv,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String displayName,
    String? displayAvatar,
    required ChatProvider chatProv,
  }) {
    final hasUnread = chat.unreadCount > 0;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isClientSide = currentUserId == chat.clientId;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chat.id,
              receiverName: displayName,
              receiverAvatar: displayAvatar,
              receiverId: isClientSide ? chat.vendorId : chat.clientId,
              chatStatus: chat.status,
            ),
          ),
        );
        chatProv.fetchChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(color: AppColors.primary.withOpacity(0.15))
              : Border.all(color: Colors.grey.shade100),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.cardCream,
              backgroundImage: displayAvatar != null
                  ? NetworkImage(displayAvatar)
                  : NetworkImage(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=96'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.updatedAt),
                        style: TextStyle(
                          color: hasUnread
                              ? AppColors.primary
                              : Colors.black38,
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatLastMessage(chat.lastMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (chat.status == 'pending') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFEBAA)),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              color: Color(0xFF856404),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                          constraints: const BoxConstraints(
                              minWidth: 20, minHeight: 20),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada percakapan',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Mulai konsultasi dengan arsitek\ndi tab Arsitek',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black38, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.architecture_outlined, size: 16),
            label: const Text('Cari Arsitek'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB ARSITEK ====================

  Widget _buildArsitekTab() {
    return Column(
      children: [
        _buildSearchBar(
          controller: _searchArchitectController,
          hint: 'Cari nama arsitek atau studio...',
          onChanged: (v) => setState(() => _searchArchitect = v),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _architectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }

              final all = snapshot.data ?? [];
              final filtered = _searchArchitect.isEmpty
                  ? all
                  : all.where((a) {
                      final profile = a['profile'] as ProfileModel;
                      final q = _searchArchitect.toLowerCase();
                      return profile.name.toLowerCase().contains(q) ||
                          (profile.companyName ?? '')
                              .toLowerCase()
                              .contains(q) ||
                          (a['location'] as String)
                              .toLowerCase()
                              .contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.architecture,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchArchitect.isEmpty
                            ? 'Belum ada arsitek terdaftar'
                            : 'Tidak ada arsitek yang cocok',
                        style: const TextStyle(
                            color: Colors.black45, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  setState(() {
                    _architectsFuture =
                        Provider.of<ArchitectProvider>(context, listen: false)
                            .fetchAllArchitects();
                  });
                  await _architectsFuture;
                },
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildArchitectCard(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArchitectCard(Map<String, dynamic> data) {
    final profile = data['profile'] as ProfileModel;
    final bio = data['bio'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final specs = data['specializations'] as Map<String, dynamic>? ?? {};
    final styles = List<String>.from(specs['styles'] ?? []);

    final displayName =
        profile.name.isNotEmpty ? profile.name : 'Arsitek';
    final studio = profile.companyName?.isNotEmpty == true
        ? profile.companyName!
        : '';
    final experience = profile.experienceYears ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArchitectDetailScreen(architectData: data),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Hero(
                    tag: 'architect_avatar_${profile.id}',
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.cardCream,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : NetworkImage(
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=128'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  color: Colors.blue, size: 14),
                            ],
                          ],
                        ),
                        if (studio.isNotEmpty)
                          Text(
                            studio,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (location.isNotEmpty) ...[
                              const Icon(Icons.location_on_outlined,
                                  size: 11, color: Colors.black38),
                              const SizedBox(width: 2),
                              Text(location,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black45)),
                              const SizedBox(width: 10),
                            ],
                            if (experience.isNotEmpty) ...[
                              const Icon(Icons.work_outline_rounded,
                                  size: 11, color: Colors.black38),
                              const SizedBox(width: 2),
                              Text('$experience thn',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black45)),
                            ],
                          ],
                        ),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            bio,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (styles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 5,
                            children: styles
                                .take(3)
                                .map((s) => _buildStyleChip(s))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6F2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArchitectDetailScreen(architectData: data),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text('Lihat Profil',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchitectDetailScreen(
                            architectData: data,
                            openChat: true,
                          ),
                        ),
                      ),
                      icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: Colors.white),
                      label: const Text('Konsultasi',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 9,
            color: AppColors.primary,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Colors.black38, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
