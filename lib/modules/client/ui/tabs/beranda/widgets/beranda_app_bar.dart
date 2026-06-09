import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/providers/chat_provider.dart';
import 'package:buildmatch/data/providers/notification_provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/ui/shared/screens/notification_screen.dart';

class BerandaAppBar extends StatelessWidget {
  final ProfileModel? profile;
  final ValueChanged<int>? onSwitchTab;

  const BerandaAppBar({
    super.key,
    required this.profile,
    this.onSwitchTab,
  });

  String _currentUserName(ProfileModel? profile, {required String fallback}) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileName = profile?.name.trim();
    final metadataName = user?.userMetadata?['name']?.toString().trim();

    if (profileName != null && profileName.isNotEmpty) return profileName;
    if (metadataName != null && metadataName.isNotEmpty) return metadataName;
    return fallback;
  }

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
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
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
    final name = _currentUserName(profile, fallback: 'Klien');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.hardware_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Build',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Consumer<ChatProvider>(
          builder: (context, chat, child) => _buildIconBtn(
            Icons.chat_bubble_outline_rounded,
            badge: chat.totalUnreadCount,
            onTap: () {
              onSwitchTab?.call(2);
            },
          ),
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, notif, child) => _buildIconBtn(
            Icons.notifications_none_rounded,
            badge: notif.unreadCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.cardCream,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'K',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
