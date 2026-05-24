import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<void> _fetchChatsFuture;

  @override
  void initState() {
    super.initState();
    _fetchChatsFuture = Provider.of<ChatProvider>(context, listen: false).fetchChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder(
        future: _fetchChatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final chats = chatProvider.chats;

              if (chats.isEmpty) {
                return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Belum ada pesan', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      // For client, display vendor info, for vendor display client info
                      // We assume if clientAvatar is not empty, it's a valid url
                      // Normally we need to know current user's role
                      final isClient = true; // Temporary mock, ideally check user role
                      
                      final displayName = chat.vendorName ?? 'Kontraktor';
                      final displayAvatar = chat.vendorAvatar;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.cardCream,
                          backgroundImage: displayAvatar != null ? NetworkImage(displayAvatar) : null,
                          child: displayAvatar == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          chat.lastMessage ?? 'Belum ada pesan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chat.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: Text(
                                  chat.unreadCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                chatId: chat.id,
                                receiverName: displayName,
                              ),
                            ),
                          ).then((_) {
                            // Refresh unread counts when returning
                            Provider.of<ChatProvider>(context, listen: false).fetchChats();
                          });
                        },
                      );
                    },
                  );
            },
          );
        },
      ),
    );
  }
}
