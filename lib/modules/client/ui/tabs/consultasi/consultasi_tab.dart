import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_state.dart';
import 'widgets/consultasi_search_bar.dart';
import 'widgets/consultasi_chat_tile.dart';
import 'widgets/consultasi_inbox_empty.dart';

class ConsultasiTab extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const ConsultasiTab({super.key, this.onSwitchTab});

  @override
  State<ConsultasiTab> createState() => _ConsultasiTabState();
}

class _ConsultasiTabState extends State<ConsultasiTab> {
  final _searchInboxController = TextEditingController();
  String _searchInbox = '';

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().fetchChats();
  }

  @override
  void dispose() {
    _searchInboxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        title: const Text(
          'Konsultasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final totalUnreadCount = state is ChatLoaded ? state.totalUnreadCount : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.black54, size: 24),
                    onPressed: () {},
                  ),
                  if (totalUnreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ConsultasiSearchBar(
            controller: _searchInboxController,
            hint: 'Cari percakapan...',
            onChanged: (v) => setState(() => _searchInbox = v),
          ),
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state is ChatInitial || state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Gagal memuat data: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (state is ChatLoaded) {
                  final allChats = [...state.chats, ...state.pendingChats];
                  allChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  var chats = allChats;

                  if (_searchInbox.isNotEmpty) {
                    final q = _searchInbox.toLowerCase();
                    chats = chats.where((c) {
                      final isClientSide = Supabase.instance.client.auth.currentUser?.id == c.clientId;
                      final name = (isClientSide ? c.vendorName : c.clientName) ?? '';
                      return name.toLowerCase().contains(q);
                    }).toList();
                  }

                  if (chats.isEmpty) {
                    return ConsultasiInboxEmpty(
                      onFindMitra: () => widget.onSwitchTab?.call(1),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => context.read<ChatCubit>().fetchChats(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: chats.length,
                      itemBuilder: (_, i) {
                        final chat = chats[i];
                        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                        final isClientSide = currentUserId == chat.clientId;
                        final displayName = isClientSide
                            ? (chat.vendorName ?? 'Mitra')
                            : (chat.clientName ?? 'Klien');
                        final displayAvatar = isClientSide
                            ? chat.vendorAvatar
                            : chat.clientAvatar;
                        return ConsultasiChatTile(
                          chat: chat,
                          displayName: displayName,
                          displayAvatar: displayAvatar,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
