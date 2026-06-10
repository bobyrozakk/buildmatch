import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';
import 'chat_detail_screen.dart';
import 'contractor_chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<void> _fetchChatsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchChatsFuture =
        Provider.of<ChatProvider>(context, listen: false).fetchChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Konsultasi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton(color: Colors.black87) : null,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _fetchChatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                return Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    var chats = chatProvider.chats;

                    // Filter search
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      chats = chats.where((c) {
                        final isClientSide = currentUserId == c.clientId;
                        final name = isClientSide
                            ? (c.vendorName ?? '')
                            : (c.clientName ?? '');
                        return name.toLowerCase().contains(q);
                      }).toList();
                    }

                    if (chats.isEmpty) {
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
                              'Mulai konsultasi dengan arsitek\nfavorit kamu',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.black38, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        await chatProvider.fetchChats();
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];

                          // Client sees vendor/architect name; vendor/arsitek sees client name
                          final isClientSide = currentUserId == chat.clientId;
                          final displayName = isClientSide
                              ? (chat.vendorName ?? 'Arsitek')
                              : (chat.clientName ?? 'Klien');
                          final displayAvatar = isClientSide
                              ? chat.vendorAvatar
                              : chat.clientAvatar;

                          return _buildChatTile(
                            context,
                            chat: chat,
                            displayName: displayName,
                            displayAvatar: displayAvatar,
                            chatProvider: chatProvider,
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
      ),
    );
  }

  Widget _buildRoleBadge(String? role) {
    if (role == null) return const SizedBox.shrink();
    final isContractor = role == 'vendor' || role == 'kontraktor';
    final isArchitect = role == 'architect' || role == 'arsitek';
    if (!isContractor && !isArchitect) return const SizedBox.shrink();

    final String label = isContractor ? 'Kontraktor' : 'Arsitek';
    final Color bgColor = isContractor 
        ? const Color(0xFFFDF2E9) // soft orange/brown
        : const Color(0xFFEBF5FB); // soft blue
    final Color textColor = isContractor 
        ? const Color(0xFFD35400) // dark orange
        : const Color(0xFF2980B9); // dark blue
    final Color borderColor = isContractor
        ? const Color(0xFFF5CBA7)
        : const Color(0xFFAED6F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context, {
    required ChatModel chat,
    required String displayName,
    String? displayAvatar,
    required ChatProvider chatProvider,
  }) {
    final hasUnread = chat.unreadCount > 0;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isClientSide = currentUserId == chat.clientId;

    return GestureDetector(
      onTap: () async {
        final isContractor = chat.vendorRole == 'vendor' || chat.vendorRole == 'kontraktor';
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isContractor
                ? ContractorChatDetailScreen(
                    chatId: chat.id,
                    receiverName: displayName,
                    receiverAvatar: displayAvatar,
                    receiverId: isClientSide ? chat.vendorId : chat.clientId,
                  )
                : ChatDetailScreen(
                    chatId: chat.id,
                    receiverName: displayName,
                    receiverAvatar: displayAvatar,
                    receiverId: isClientSide ? chat.vendorId : chat.clientId,
                    chatStatus: chat.status,
                  ),
          ),
        );
        chatProvider.fetchChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(color: AppColors.primary.withOpacity(0.2))
              : Border.all(color: Colors.grey.shade100),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.cardCream,
              backgroundImage: displayAvatar != null
                  ? NetworkImage(displayAvatar)
                  : NetworkImage(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=96'),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight:
                                      hasUnread ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge(isClientSide ? chat.vendorRole : null),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.updatedAt),
                        style: TextStyle(
                          color:
                              hasUnread ? AppColors.primary : Colors.black38,
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
                            color: hasUnread ? Colors.black87 : Colors.grey,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
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
}
