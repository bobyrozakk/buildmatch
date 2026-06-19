import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/modules/client/ui/screens/architect_detail/architect_detail_screen.dart';

class BerandaTopPartners extends StatelessWidget {
  final List<Map<String, dynamic>> partners;

  const BerandaTopPartners({super.key, required this.partners});

  Map<String, dynamic> _getPartnerDetailData(ProfileModel profile) {
    Map<String, dynamic> specializations = {};
    String bio = '';
    String location = '';

    if (profile.role == 'architect') {
      if (profile.nib != null && profile.nib!.startsWith('{')) {
        try {
          final data = jsonDecode(profile.nib!);
          bio = data['bio'] ?? '';
          location = data['location'] ?? '';
          specializations = Map<String, dynamic>.from(data['specializations'] ?? {});
        } catch (_) {}
      }
    } else {
      bio = 'Penyedia jasa kontraktor profesional terpercaya untuk menangani berbagai kebutuhan konstruksi, renovasi, dan pembangunan fisik bangunan Anda.';
      location = profile.companyName ?? 'Indonesia';
      specializations = {
        'styles': ['Struktur', 'Finishing', 'Renovasi', 'Dinding & Lantai'],
        'project_types': ['Rumah Tinggal', 'Ruko', 'Apartemen', 'Kantor'],
        'technical_skills': ['Rencana Anggaran Biaya (RAB)', 'Manajemen Konstruksi', 'Pekerjaan Sipil'],
      };
    }

    return {
      'profile': profile,
      'bio': bio,
      'location': location,
      'specializations': specializations,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, color: Colors.black26, size: 40),
              SizedBox(height: 10),
              Text(
                'Belum ada data mitra terpopuler',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black38,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: partners.length,
        itemBuilder: (context, i) {
          final item = partners[i];
          final profile = item['profile'] as ProfileModel;
          final avgRating = item['avgRating'] as double;

          final isArchitect = profile.role == 'architect';
          final badgeLabel = isArchitect ? 'Arsitek' : 'Kontraktor';
          final badgeBgColor = isArchitect
              ? const Color(0xFFE0F2F1)
              : AppColors.primary.withValues(alpha: 0.1);
          final badgeTextColor = isArchitect
              ? const Color(0xFF00796B)
              : AppColors.primary;

          final displayName = profile.companyName?.isNotEmpty == true
              ? profile.companyName!
              : profile.name;

          return GestureDetector(
            onTap: () {
              final detailData = _getPartnerDetailData(profile);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArchitectDetailScreen(architectData: detailData),
                ),
              );
            },
            child: Container(
              width: 190,
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 6,
                right: i == partners.length - 1 ? 0 : 6,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'architect_avatar_${profile.id}',
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.cardCream,
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(profile.avatarUrl!)
                              : NetworkImage(
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(profile.name)}&background=${isArchitect ? "8B2B0F" : "B53D1B"}&color=fff&size=128',
                                ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${profile.collabCount ?? 0} proyek)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
