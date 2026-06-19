// lib/modules/kontraktor/ui/tabs/profile/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/modules/auth/logic/auth_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/profile_edit/profile_edit_screen.dart';
import 'package:buildmatch/modules/auth/ui/login_screen.dart';
import 'package:buildmatch/core/constants/colors.dart';

import 'widgets/profile_header.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_porto_card.dart';
import 'widgets/profile_cert_card.dart';
import 'widgets/profile_review_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final cubit = context.read<VendorCubit>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";

    cubit.fetchVendorProfile();
    cubit.fetchPortfolios();
    cubit.fetchCertifications();
    cubit.fetchReviews(userId);
  }

  Future<void> _refresh() async {
    _load();
  }

  void _navigateToEditProfile({int initialTab = 0}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialTab: initialTab),
      ),
    );
    if (result == true && mounted) {
      _load();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFCF8F5),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun ini?',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authCubit = context.read<AuthCubit>();
      await authCubit.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.hardware_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'Build',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary)),
                TextSpan(
                    text: 'Match',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
              ]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 22),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: BlocBuilder<VendorCubit, VendorState>(
          builder: (context, state) {
            if (state is VendorLoading || state is VendorInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is VendorError) {
              return Center(child: Text(state.message));
            }
            if (state is VendorLoaded) {
              final profile = state.vendorProfile;
              final portfolios = state.portfolios;
              final certifications = state.certifications;
              final reviews = state.reviews;

              double totalRating = 0;
              for (final r in reviews) {
                totalRating += (r['rating'] as num?)?.toDouble() ?? 0.0;
              }
              final avgRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
              final rating = avgRating.toStringAsFixed(1);
              final reviewsCount = reviews.length.toString();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileHeader(
                      profile: profile,
                      rating: rating,
                      reviewsCount: reviewsCount,
                      onEditTap: _navigateToEditProfile,
                    ),
                    const SizedBox(height: 24),
                    ProfileStats(
                      portfolioCount: portfolios.length,
                      certificationCount: certifications.length,
                      rating: rating,
                      reviewsCount: reviewsCount,
                    ),
                    const SizedBox(height: 28),
                    // Portofolio Section
                    const Text(
                      'Portofolio Publik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (portfolios.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.design_services_outlined, size: 36, color: Colors.black38),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada portofolio yang diunggah.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: portfolios.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, i) {
                          return ProfilePortoCard(portfolio: portfolios[i]);
                        },
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToEditProfile(initialTab: 1),
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text(
                          'Tambah Portofolio',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Sertifikasi & Lisensi Section
                    const Text(
                      'Sertifikasi & Lisensi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (certifications.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada sertifikasi terdaftar.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      ...certifications.map((cert) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ProfileCertCard(certification: cert),
                        );
                      }),
                    const SizedBox(height: 32),
                    // Ulasan Klien Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ulasan Klien',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$rating/5.0',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: Colors.orange, size: 14),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      'Kepuasan klien adalah reputasi terbaik kami',
                      style: TextStyle(color: Colors.black45, fontSize: 11, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    if (reviews.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 36, color: Colors.black38),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada ulasan dari klien.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...reviews.take(4).map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ProfileReviewCard(review: r),
                        );
                      }),
                    if (reviews.length > 4) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () =>
                              _showAllReviewsBottomSheet(context, reviews, rating),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lihat Semua Ulasan',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                        label: const Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.red.shade50.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAllReviewsBottomSheet(
      BuildContext context, List<Map<String, dynamic>> reviews, String rating) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Semua Ulasan Klien',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Text(
                            '$rating/5.0',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: reviews.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ProfileReviewCard(review: reviews[i]),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}