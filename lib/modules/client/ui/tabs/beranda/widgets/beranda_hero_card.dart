import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/core/constants/colors.dart';

class BerandaHeroCard extends StatelessWidget {
  final ProfileModel? profile;
  final VoidCallback onMulaiProyek;

  const BerandaHeroCard({
    super.key,
    required this.profile,
    required this.onMulaiProyek,
  });

  String _currentUserName(ProfileModel? profile, {required String fallback}) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileName = profile?.name.trim();
    final metadataName = user?.userMetadata?['name']?.toString().trim();

    if (profileName != null && profileName.isNotEmpty) return profileName;
    if (metadataName != null && metadataName.isNotEmpty) return metadataName;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final name = _currentUserName(profile, fallback: 'Klien');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat datang,',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bangun rumah impianmu mulai dari sini. Buat proyek, dapatkan penawaran terbaik dari kontraktor.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onMulaiProyek,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mulai Proyek',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
