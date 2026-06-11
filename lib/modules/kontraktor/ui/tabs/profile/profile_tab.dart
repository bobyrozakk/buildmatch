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
import 'widgets/profile_menu_tile.dart';

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
      body: BlocBuilder<VendorCubit, VendorState>(
        builder: (context, state) {
          if (state is VendorLoading || state is VendorInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }
          if (state is VendorError) {
            return Center(child: Text(state.message));
          }
          if (state is VendorLoaded) {
            final profile = state.vendorProfile;
            final portfolios = state.portfolios;
            final certifications = state.certifications;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    profile: profile,
                    onEditTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      setState(() {
                        _load();
                      });
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: ProfileStats(
                      portfolioCount: portfolios.length,
                      reviews: state.reviews,
                    ),
                  ),
                ),
                _title('Portofolio'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: portfolios.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada portofolio',
                              style: TextStyle(
                                color: Colors.black38,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: portfolios.length,
                            itemBuilder: (_, i) => ProfilePortoCard(
                              portfolio: portfolios[i],
                            ),
                          ),
                  ),
                ),
                _title('Sertifikasi'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProfileCertCard(
                        certification: certifications[i],
                      ),
                      childCount: certifications.length,
                    ),
                  ),
                ),
                _title('Pengaturan'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        ProfileMenuTile(
                          icon: Icons.edit_outlined,
                          title: 'Kelola Profil',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                            setState(() {
                              _load();
                            });
                          },
                        ),
                        ProfileMenuTile(
                          icon: Icons.reviews_outlined,
                          title: 'Lihat Ulasan',
                          onTap: () {},
                        ),
                        ProfileMenuTile(
                          icon: Icons.support_agent_outlined,
                          title: 'Hubungi CS',
                          onTap: () {},
                        ),
                        ProfileMenuTile(
                          icon: Icons.logout_rounded,
                          title: 'Keluar',
                          onTap: _logout,
                          isDanger: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _title(String text) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      sliver: SliverToBoxAdapter(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}