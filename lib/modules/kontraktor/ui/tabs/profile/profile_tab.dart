import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/modules/auth/logic/auth_cubit.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/models/portfolio_model.dart';
import 'package:buildmatch/data/models/certification_model.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/modules/kontraktor/ui/screens/profile_edit/profile_edit_screen.dart';
import 'package:buildmatch/modules/auth/ui/login_screen.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/core/constants/colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() =>
      _ProfileTabState();
}

class _ProfileTabState
    extends State<ProfileTab> {

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
      backgroundColor:
          AppColors.backgroundCream,

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
            physics:
                const BouncingScrollPhysics(),
            slivers: [

              SliverToBoxAdapter(
                child: _header(profile),
              ),

              SliverPadding(
                padding:
                    const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: _stats(portfolios, state.reviews),
                ),
              ),

              _title('Portofolio'),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: portfolios.isEmpty
                      ? _empty(
                          'Belum ada portofolio',
                        )
                      : ListView.builder(
                          scrollDirection:
                              Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          itemCount:
                              portfolios.length,
                          itemBuilder: (_, i) =>
                              _portoCard(
                            portfolios[i],
                          ),
                        ),
                ),
              ),

              _title('Sertifikasi'),

              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (_, i) => _certCard(
                      certifications[i],
                    ),
                    childCount:
                        certifications.length,
                  ),
                ),
              ),

              _title('Pengaturan'),

              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [

                      _menuTile(
                        Icons.edit_outlined,
                        'Kelola Profil',
                        () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EditProfileScreen(),
                            ),
                          );

                          setState(() {
                            _load();
                          });
                        },
                      ),

                      _menuTile(
                        Icons.reviews_outlined,
                        'Lihat Ulasan',
                        () {},
                      ),

                      _menuTile(
                        Icons.support_agent_outlined,
                        'Hubungi CS',
                        () {},
                      ),

                      _menuTile(
                        Icons.logout_rounded,
                        'Keluar',
                        _logout,
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

Widget _header(ProfileModel? p) {
  return Stack(
    children: [

      Container(
        height: 170,
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
      ),

      Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          70,
          20,
          0,
        ),

        child: IOSGlassCard(
          blur: 18,

          child: Padding(
            padding: const EdgeInsets.all(22),

            child: Row(
              children: [

                CircleAvatar(
                  radius: 38,
                  backgroundColor:
                      Colors.white,

                  backgroundImage:
                      p?.avatarUrl != null
                          ? NetworkImage(
                              p!.avatarUrl!,
                            )
                          : null,

                  child: p?.avatarUrl == null
                      ? Text(
                          (p?.name ?? 'V')
                              .substring(0, 1)
                              .toUpperCase(),
                          style:
                              const TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppColors.primary,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        p?.companyName ??
                            'Vendor Company',

                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        p?.name ?? '',
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 10),

                      if (p?.isVerified ==
                          true)
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .green
                                .withOpacity(
                              0.12,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),

                          child: const Text(
                            '✓ Vendor Terverifikasi',

                            style: TextStyle(
                              color:
                                  Colors.green,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const EditProfileScreen(),
                      ),
                    );

                    setState(() {
                      _load();
                    });
                  },

                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _stats(
    List<PortfolioModel> portfolios,
    List<Map<String, dynamic>> reviews,
  ) {
    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num? ?? 0.0));
      avgRating = total / reviews.length;
    }
    final ratingStr = reviews.isEmpty ? '0.0' : avgRating.toStringAsFixed(1);

    return Row(
      children: [

        _statBox(
          portfolios.length.toString(),
          'Portofolio',
        ),

        const SizedBox(width: 12),

        _statBox(ratingStr, 'Rating'),

        const SizedBox(width: 12),

        _statBox('Aktif', 'Status'),
      ],
    );
  }

  Widget _statBox(
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Column(
          children: [

            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) {
    return SliverPadding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        14,
      ),
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

  Widget _portoCard(PortfolioModel p) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        image: p.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(
                  p.imageUrl!,
                ),
                fit: BoxFit.cover,
              )
            : null,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _certCard(
    CertificationModel c,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  AppColors.cardCream,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  c.title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  c.issuer,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDanger
              ? Colors.red
              : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDanger
                ? Colors.red
                : Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black38,
        ),
      ),
    );
  }
}