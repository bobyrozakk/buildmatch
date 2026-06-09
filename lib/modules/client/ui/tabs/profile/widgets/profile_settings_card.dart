import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileSettingsCard extends StatelessWidget {
  final VoidCallback onEditPassword;
  final VoidCallback onNotification;
  final VoidCallback onHelp;
  final VoidCallback onTerms;

  const ProfileSettingsCard({
    super.key,
    required this.onEditPassword,
    required this.onNotification,
    required this.onHelp,
    required this.onTerms,
  });

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.backgroundCream, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSettingItem(Icons.lock_outline, "Ubah Password", onEditPassword),
          _divider(),
          _buildSettingItem(Icons.notifications_none_rounded, "Notifikasi", onNotification),
          _divider(),
          _buildSettingItem(Icons.help_outline_rounded, "Bantuan & FAQ", onHelp),
          _divider(),
          _buildSettingItem(Icons.description_outlined, "Syarat & Ketentuan", onTerms),
        ],
      ),
    );
  }
}
