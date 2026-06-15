import 'package:flutter/material.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel? profile;
  final String rating;
  final String reviewsCount;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.rating,
    required this.reviewsCount,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? 'Vendor';
    final companyName = profile?.companyName ?? 'Nama Perusahaan';

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.cardCream,
                  backgroundImage: profile?.avatarUrl != null &&
                          profile!.avatarUrl!.isNotEmpty
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null ||
                          profile!.avatarUrl!.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'V',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
                  child: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 14,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            companyName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'PIC: $name',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Edit Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(
                '$rating ($reviewsCount Ulasan)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 12, color: Colors.black26),
              const SizedBox(width: 16),
              Icon(
                profile?.isVerified == true
                    ? Icons.verified_rounded
                    : Icons.verified_user_outlined,
                color: profile?.isVerified == true ? Colors.green : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                profile?.isVerified == true ? 'Terverifikasi' : 'Belum Verifikasi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: profile?.isVerified == true ? Colors.green : Colors.black54,
                ),
              ),
            ],
          ),
          if (profile?.nib != null && profile!.nib!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'NIB: ${profile!.nib}  •  NPWP: ${profile!.npwp ?? "-"}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
