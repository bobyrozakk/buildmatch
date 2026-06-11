import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_state.dart';
import 'package:buildmatch/ui/shared/screens/chat_list_screen.dart';
import 'package:buildmatch/ui/shared/screens/notification_screen.dart';

class BerandaAppBar extends StatelessWidget {
  final ProfileModel? profile;
  final VoidCallback onAvatarTap;

  const BerandaAppBar({
    super.key,
    required this.profile,
    required this.onAvatarTap,
  });

  Widget _buildIconBtn(IconData icon, {VoidCallback? onTap, int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardCream,
              borderRadius: BorderRadius.circular(12),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
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
          onTap: onAvatarTap,
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
}
