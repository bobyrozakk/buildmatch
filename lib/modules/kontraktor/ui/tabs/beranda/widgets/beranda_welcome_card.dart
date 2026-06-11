import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';

class BerandaWelcomeCard extends StatelessWidget {
  final ProfileModel? profile;
  final VoidCallback onTap;

  const BerandaWelcomeCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  double _profileCompletion(ProfileModel? p) {
    if (p == null) return 0.0;
    int filled = 0;
    const total = 6;
    if (p.name.isNotEmpty) filled++;
    if (p.companyName?.isNotEmpty == true) filled++;
    if (p.phone?.isNotEmpty == true) filled++;
    if (p.npwp?.isNotEmpty == true) filled++;
    if (p.straNumber?.isNotEmpty == true) filled++;
    if (p.avatarUrl?.isNotEmpty == true) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.userMetadata?['name'] ?? 'Kontraktor');
    final company = profile?.companyName ?? 'Vendor BuildMatch';
    final completion = _profileCompletion(profile);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(company, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                if (profile?.isVerified == true) ...[
                  const Icon(Icons.verified, color: Colors.white, size: 14),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Profil ${(completion * 100).toInt()}% lengkap', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('${(completion * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lengkapi Sekarang', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
