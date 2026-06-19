import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/modules/client/ui/screens/architect_detail/architect_detail_screen.dart';

class ContractorTabContent extends StatefulWidget {
  const ContractorTabContent({super.key});

  @override
  State<ContractorTabContent> createState() => _ContractorTabContentState();
}

class _ContractorTabContentState extends State<ContractorTabContent> {
  final _searchContractorController = TextEditingController();
  String _searchContractor = '';
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

  Map<String, dynamic> _getPartnerDetailData(ProfileModel profile) {
    return {
      'profile': profile,
      'bio': 'Penyedia jasa kontraktor profesional terpercaya untuk menangani berbagai kebutuhan konstruksi, renovasi, dan pembangunan fisik bangunan Anda.',
      'location': profile.companyName ?? 'Indonesia',
      'specializations': {
        'styles': ['Struktur', 'Finishing', 'Renovasi', 'Dinding & Lantai'],
        'project_types': ['Rumah Tinggal', 'Ruko', 'Apartemen', 'Kantor'],
        'technical_skills': ['Rencana Anggaran Biaya (RAB)', 'Manajemen Konstruksi', 'Pekerjaan Sipil'],
      },
    };
  }

  @override
  void dispose() {
    _searchContractorController.dispose();
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
              controller: _searchContractorController,
              onChanged: (v) => setState(() => _searchContractor = v),
              decoration: const InputDecoration(
                hintText: "Cari nama kontraktor...",
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
            ],
          ),
        ),

        // List
        Expanded(
          child: BlocBuilder<VendorCubit, VendorState>(
            builder: (context, state) {
              if (state is VendorInitial || state is VendorLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state is VendorError) {
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

              if (state is VendorLoaded) {
                final all = state.vendors;
                final filtered = _searchContractor.isEmpty
                    ? all
                    : all.where((v) => v.name.toLowerCase().contains(_searchContractor.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyContractors();
                }

                final sorted = List<ProfileModel>.from(filtered);
                if (_sortBy == 'collab') {
                  sorted.sort((a, b) => (b.collabCount ?? 0).compareTo(a.collabCount ?? 0));
                } else if (_sortBy == 'rating') {
                  sorted.sort((a, b) => (b.avgRating ?? 0.0).compareTo(a.avgRating ?? 0.0));
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => context.read<VendorCubit>().fetchVendors(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final vendor = sorted[i];
                      return _buildVendorCard(vendor);
                    },
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

  Widget _buildVendorCard(ProfileModel vendor) {
    final displayName = vendor.name.isNotEmpty ? vendor.name : 'Kontraktor';
    final studio = vendor.companyName?.isNotEmpty == true ? vendor.companyName! : '';
    final hasPhone = vendor.phone?.isNotEmpty == true;

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
                  tag: 'architect_avatar_${vendor.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.cardCream,
                    backgroundImage: vendor.avatarUrl != null
                        ? NetworkImage(vendor.avatarUrl!)
                        : NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=B53D1B&color=fff&size=128',
                          ),
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
                          if (vendor.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 14),
                          ],
                        ],
                      ),
                      if (studio.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          studio,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            vendor.avgRating?.toStringAsFixed(1) ?? '0.0',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chat_bubble_outline_rounded, color: Colors.black38, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${vendor.collabCount ?? 0} proyek',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                      if (hasPhone) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 11, color: Colors.black38),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                vendor.phone!,
                                style: const TextStyle(fontSize: 11, color: Colors.black45),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                    onPressed: () {
                      final detailData = _getPartnerDetailData(vendor);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchitectDetailScreen(architectData: detailData),
                        ),
                      );
                    },
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
                    onPressed: () {
                      final detailData = _getPartnerDetailData(vendor);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchitectDetailScreen(
                            architectData: detailData,
                            openChat: true,
                          ),
                        ),
                      );
                    },
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

  Widget _buildEmptyContractors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada Mitra Kontraktor", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
          const Text("Sistem sedang menunggu kontraktor bergabung.", style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}
