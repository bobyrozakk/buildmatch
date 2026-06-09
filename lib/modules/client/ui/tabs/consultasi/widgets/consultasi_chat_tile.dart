import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/chat_model.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/ui/shared/screens/chat_detail_screen.dart';
import 'package:buildmatch/ui/shared/screens/contractor_chat_detail_screen.dart';
import 'consultasi_role_badge.dart';

class ConsultasiChatTile extends StatelessWidget {
  final ChatModel chat;
  final String displayName;
  final String? displayAvatar;

  const ConsultasiChatTile({
    super.key,
    required this.chat,
    required this.displayName,
    this.displayAvatar,
  });

  String _formatLastMessage(String? content) {
    if (content == null || content.isEmpty) return 'Belum ada pesan';

    if (content.startsWith('{')) {
      try {
        final data = jsonDecode(content) as Map<String, dynamic>;
        final type = data['type'] as String?;
        if (type == 'offer') {
          return '📋 Penawaran telah dikirim';
        } else if (type == 'design') {
          final rev = data['revision_number'] as int? ?? 1;
          return '🎨 Revisi ke-$rev telah diberikan';
        }
      } catch (_) {}
    }

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
    final hasUnread = chat.unreadCount > 0;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isClientSide = currentUserId == chat.clientId;

    return GestureDetector(
      onTap: () async {
        final cubit = context.read<ChatCubit>();
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
        cubit.fetchChats();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.15))
              : Border.all(color: Colors.grey.shade100),
          boxShadow: hasUnread
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
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
                  ? NetworkImage(displayAvatar!)
                  : NetworkImage(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=96',
                    ),
            ),
            const SizedBox(width: 12),
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
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConsultasiRoleBadge(role: chat.vendorRole),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.updatedAt),
                        style: TextStyle(
                          color: hasUnread ? AppColors.primary : Colors.black38,
                          fontSize: 11,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
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
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
