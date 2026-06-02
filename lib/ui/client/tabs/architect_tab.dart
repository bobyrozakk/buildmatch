import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/architect_provider.dart';
import '../screens/architect_detail_screen.dart';

class ArchitectTab extends StatefulWidget {
  const ArchitectTab({super.key});

  @override
  State<ArchitectTab> createState() => _ArchitectTabState();
}

class _ArchitectTabState extends State<ArchitectTab> {
  late Future<List<Map<String, dynamic>>> _architectsFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _architectsFuture =
        Provider.of<ArchitectProvider>(context, listen: false).fetchAllArchitects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _architectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final allArchitects = snapshot.data ?? [];
                  final filtered = _searchQuery.isEmpty
                      ? allArchitects
                      : allArchitects.where((a) {
                          final profile = a['profile'] as ProfileModel;
                          final q = _searchQuery.toLowerCase();
                          return profile.name.toLowerCase().contains(q) ||
                              (profile.companyName ?? '').toLowerCase().contains(q) ||
                              (a['location'] as String).toLowerCase().contains(q);
                        }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      setState(() {
                        _architectsFuture = Provider.of<ArchitectProvider>(
                          context,
                          listen: false,
                        ).fetchAllArchitects();
                      });
                      await _architectsFuture;
                    },
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _buildArchitectCard(filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.architecture, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Arsitek',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Temukan arsitek profesional untuk desain rumah impianmu',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'Cari nama arsitek atau studio...',
            hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArchitectDetailScreen(architectData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'architect_avatar_${profile.id}',
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.cardCream,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : NetworkImage(
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=8B2B0F&color=fff&size=128',
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 15),
                            ],
                          ],
                        ),
                        if (studio.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            studio,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (location.isNotEmpty || experience.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: [
                              if (location.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.black45),
                                    const SizedBox(width: 2),
                                    Text(location, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              if (experience.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.work_outline_rounded, size: 12, color: Colors.black45),
                                    const SizedBox(width: 2),
                                    Text('$experience thn', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bio
            if (bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  bio,
                  style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Style Chips
            if (styles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: styles.take(3).map((s) => _buildChip(s)).toList(),
                ),
              ),

            // Divider + Buttons
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArchitectDetailScreen(architectData: data),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Lihat Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArchitectDetailScreen(
                              architectData: data,
                              openChat: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Colors.white),
                      label: const Text('Konsultasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada arsitek',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Arsitek akan muncul di sini setelah mendaftar'
                : 'Tidak ada arsitek yang cocok dengan pencarian',
            style: const TextStyle(fontSize: 13, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
