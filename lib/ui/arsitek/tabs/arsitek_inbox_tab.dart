import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../../core/constants/colors.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/providers/notification_provider.dart';
import '../../shared/screens/notification_screen.dart';
import '../../shared/screens/chat_detail_screen.dart';

class ArsitekInboxTab extends StatefulWidget {
  const ArsitekInboxTab({super.key});

  @override
  State<ArsitekInboxTab> createState() => _ArsitekInboxTabState();
}

class _ArsitekInboxTabState extends State<ArsitekInboxTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _fetchFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFuture =
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  String _formatLastMessage(String? content) {
    if (content == null || content.isEmpty) return 'Belum ada pesan';

    if (content.startsWith('{')) {
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'offer') return '📋 Penawaran telah dikirim';
        if (type == 'design') {
          final rev = data['revision_number'] as int? ?? 1;
          return '🎨 Revisi ke-$rev telah diberikan';
        }
      } catch (_) {}
    }

    if (content.startsWith('http://') || content.startsWith('https://')) {
      final lower = content.toLowerCase();
      final isImage = lower.contains('.png') || lower.contains('.jpg') ||
          lower.contains('.jpeg') || lower.contains('.gif') ||
          lower.contains('.webp');
      if (isImage) return '🖼️ Gambar dilampirkan';
      return '📎 File dilampirkan';
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.hardware_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'Build',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary)),
                TextSpan(
                    text: 'Match',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
              ]),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, child) => GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.cardCream,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<ChatProvider>(
            builder: (_, chatProv, __) {
              final pendingCount = chatProv.pendingChats.length;
              return TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.black54,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 14),
                tabs: [
                  const Tab(text: 'Pesan'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Permintaan'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPesanTab(),
              _buildPermintaanTab(),
            ],
          );
        },
      ),
    );
  }

  // ==================== TAB PESAN (accepted chats) ====================

  Widget _buildPesanTab() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Cari percakapan...',
                hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                prefixIcon:
                    Icon(Icons.search, color: Colors.black45, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (_, chatProv, __) {
              var chats = chatProv.chats; // accepted only

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                chats = chats.where((c) {
                  // Arsitek = vendor side → tampilkan nama client
                  final name = c.clientName ?? '';
                  return name.toLowerCase().contains(q);
                }).toList();
              }

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Belum ada pesan aktif',
                          style: TextStyle(
                              color: Colors.black45, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        'Terima permintaan klien\nuntuk memulai percakapan',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.black38, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => chatProv.fetchChats(),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat = chats[i];
                    // Arsitek adalah vendor side → tampilkan nama client
                    final displayName = chat.clientName ?? 'Klien';
                    final displayAvatar = chat.clientAvatar;

                    return _buildChatItem(
                      chat: chat,
                      displayName: displayName,
                      displayAvatar: displayAvatar,
                      chatProv: chatProv,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem({
    required ChatModel chat,
    required String displayName,
    String? displayAvatar,
    required ChatProvider chatProv,
  }) {
    final isActive = chat.unreadCount > 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chat.id,
              receiverName: displayName,
              receiverAvatar: displayAvatar,
              receiverId: chat.clientId,
            ),
          ),
        );
        chatProv.fetchChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isActive)
                Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTime(chat.updatedAt),
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.black38,
                                    fontSize: 10,
                                    fontWeight: isActive
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
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.black87
                                          : Colors.black45,
                                      fontSize: 12,
                                      fontWeight: isActive
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle),
                                    child: Text(
                                      '${chat.unreadCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB PERMINTAAN (pending chats) ====================

  Widget _buildPermintaanTab() {
    return Consumer<ChatProvider>(
      builder: (_, chatProv, __) {
        final pendingChats = chatProv.pendingChats;

        if (pendingChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inbox_rounded,
                      size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada permintaan baru',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permintaan konsultasi dari klien\nakan muncul di sini',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black38, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => chatProv.fetchChats(),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: pendingChats.length,
            itemBuilder: (_, i) =>
                _buildPermintaanCard(pendingChats[i], chatProv),
          ),
        );
      },
    );
  }

  Widget _buildPermintaanCard(ChatModel chat, ChatProvider chatProv) {
    final clientName = chat.clientName ?? 'Klien';
    final clientAvatar = chat.clientAvatar;
    final lastMsg = chat.lastMessage != null && chat.lastMessage!.isNotEmpty
        ? _formatLastMessage(chat.lastMessage)
        : 'Ingin berkonsultasi dengan Anda';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.cardCream,
                    backgroundImage: clientAvatar != null
                        ? NetworkImage(clientAvatar)
                        : NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(clientName)}&background=8B2B0F&color=fff&size=96'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Client',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(chat.updatedAt),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pesan pertama
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EBE3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('"',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lastMsg,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 12, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Tolak & Terima
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Tolak Permintaan'),
                        content: Text(
                            'Tolak permintaan dari $clientName?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Batal')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Tolak',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await chatProv.rejectChat(chat.id);
                    }
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Tolak',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8F2A0C),
                    side: const BorderSide(color: Color(0xFF8F2A0C)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await chatProv.acceptChat(chat.id);
                    if (ok && mounted) {
                      // Langsung buka chat room setelah terima
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chat.id,
                            receiverName: clientName,
                            receiverAvatar: clientAvatar,
                            receiverId: chat.clientId,
                          ),
                        ),
                      );
                      // Pindah ke tab Pesan
                      _tabController.animateTo(0);
                    }
                  },
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: const Text('Terima',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F2A0C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
