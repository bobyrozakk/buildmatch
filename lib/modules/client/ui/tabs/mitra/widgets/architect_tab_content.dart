import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/providers/architect_provider.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/modules/client/ui/screens/architect_detail/architect_detail_screen.dart';

class ArchitectTabContent extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> architectsFuture;
  final Future<void> Function() onRefresh;

  const ArchitectTabContent({
    super.key,
    required this.architectsFuture,
    required this.onRefresh,
  });

  @override
  State<ArchitectTabContent> createState() => _ArchitectTabContentState();
}

class _ArchitectTabContentState extends State<ArchitectTabContent> {
  final _searchArchitectController = TextEditingController();
  String _searchArchitect = '';

  @override
  void dispose() {
    _searchArchitectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: IOSGlassCard(
            blur: 15,
            child: TextField(
              controller: _searchArchitectController,
              onChanged: (v) => setState(() => _searchArchitect = v),
              decoration: const InputDecoration(
                hintText: "Cari nama arsitek atau studio...",
                hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.architectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final all = snapshot.data ?? [];
              final filtered = _searchArchitect.isEmpty
                  ? all
                  : all.where((a) {
                      final profile = a['profile'] as ProfileModel;
                      final q = _searchArchitect.toLowerCase();
                      return profile.name.toLowerCase().contains(q) ||
                          (profile.companyName ?? '').toLowerCase().contains(q) ||
                          (a['location'] as String).toLowerCase().contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return _buildEmptyArchitects();
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: widget.onRefresh,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildArchitectCard(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArchitectCard(Map<String, dynamic> data) {
    final profile = data['profile'] as ProfileModel;
    final bio = data['bio'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final specs = data['specializations'] as Map<String, dynamic>? ?? {};
    final styles = List<String>.from(specs['styles'] ?? []);

    final displayName = profile.name.isNotEmpty ? profile.name : 'Arsitek';
    final studio = profile.companyName?.isNotEmpty == true ? profile.companyName! : '';
    final experience = profile.experienceYears ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Hero(
                  tag: 'architect_avatar_${profile.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cardCream,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=128'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                          ],
                        ],
                      ),
                      if (studio.isNotEmpty)
                        Text(
                          studio,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (location.isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined, size: 11, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text(location, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                            const SizedBox(width: 10),
                          ],
                          if (experience.isNotEmpty) ...[
                            const Icon(Icons.work_outline_rounded, size: 11, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text('$experience thn', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        ],
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (styles.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          children: styles.take(3).map((s) => _buildStyleChip(s)).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAF6F2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArchitectDetailScreen(architectData: data),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Lihat Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArchitectDetailScreen(
                          architectData: data,
                          openChat: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                    label: const Text('Konsultasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyArchitects() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada Mitra Arsitek", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
          const Text("Sistem sedang menunggu arsitek bergabung.", style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}
