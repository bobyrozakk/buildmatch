import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/modules/client/logic/architect/architect_cubit.dart';
import 'package:buildmatch/modules/client/logic/architect/architect_state.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/modules/client/ui/screens/architect_detail/architect_detail_screen.dart';

class ArchitectTabContent extends StatefulWidget {
  const ArchitectTabContent({super.key});

  @override
  State<ArchitectTabContent> createState() => _ArchitectTabContentState();
}

class _ArchitectTabContentState extends State<ArchitectTabContent> {
  final _searchArchitectController = TextEditingController();
  String _searchArchitect = '';
  String _sortBy = 'terbaru';

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _sortBy == key;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

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

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              _buildFilterChip('Terbaru', 'terbaru'),
              const SizedBox(width: 8),
              _buildFilterChip('Proyek Terbanyak', 'collab'),
              const SizedBox(width: 8),
              _buildFilterChip('Rating Tertinggi', 'rating'),
              const SizedBox(width: 8),
              _buildFilterChip('Pengalaman Terlama', 'experience'),
            ],
          ),
        ),

        // List
        Expanded(
          child: BlocBuilder<ArchitectCubit, ArchitectState>(
            builder: (context, state) {
              if (state is ArchitectInitial || state is ArchitectLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state is ArchitectError) {
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

              if (state is ArchitectLoaded) {
                final all = state.architects;
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

                final sorted = List<Map<String, dynamic>>.from(filtered);
                if (_sortBy == 'collab') {
                  sorted.sort((a, b) {
                    final countA = a['collabCount'] as int? ?? 0;
                    final countB = b['collabCount'] as int? ?? 0;
                    return countB.compareTo(countA);
                  });
                } else if (_sortBy == 'rating') {
                  sorted.sort((a, b) {
                    final ratingA = (a['profile'] as ProfileModel).avgRating ?? 0.0;
                    final ratingB = (b['profile'] as ProfileModel).avgRating ?? 0.0;
                    return ratingB.compareTo(ratingA);
                  });
                } else if (_sortBy == 'experience') {
                  sorted.sort((a, b) {
                    final expA = int.tryParse((a['profile'] as ProfileModel).experienceYears ?? '0') ?? 0;
                    final expB = int.tryParse((b['profile'] as ProfileModel).experienceYears ?? '0') ?? 0;
                    return expB.compareTo(expA);
                  });
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => context.read<ArchitectCubit>().fetchAllArchitects(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) => _buildArchitectCard(sorted[i]),
                  ),
                );
              }

              return const SizedBox.shrink();
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
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (experience.isNotEmpty) ...[
                            const Icon(Icons.work_outline_rounded, size: 11, color: Colors.black38),
                            const SizedBox(width: 2),
                            Text('$experience thn', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            profile.avgRating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black38, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${profile.collabCount ?? 0} proyek',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
