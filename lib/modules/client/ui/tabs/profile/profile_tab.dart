import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/modules/auth/logic/auth_cubit.dart';
import 'package:buildmatch/modules/auth/logic/auth_state.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/auth/ui/login_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/profile_edit/profile_edit_screen.dart';
import 'package:buildmatch/modules/client/ui/screens/create_project/create_project_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats_row.dart';
import 'widgets/profile_projects_list.dart';
import 'widgets/profile_settings_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];
  int _activeProjectsCount = 0;
  int _completedProjectsCount = 0;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final cubit = context.read<ProjectCubit>();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await cubit.fetchClientProjectsWithContractor();
      
      int activeCount = 0;
      int completedCount = 0;
      for (final item in list) {
        final project = item['project'] as ProjectModel;
        if (project.status == 'in_progress') {
          activeCount++;
        } else if (project.status == 'completed') {
          completedCount++;
        }
      }
      
      final userId = _supabase.auth.currentUser?.id;
      int reviewsCount = 0;
      if (userId != null) {
        final reviewsResponse = await _supabase
            .from('reviews')
            .select('id')
            .eq('user_id', userId);
        reviewsCount = (reviewsResponse as List).length;
      }
      
      if (mounted) {
        setState(() {
          _projects = list;
          _activeProjectsCount = activeCount;
          _completedProjectsCount = completedCount;
          _reviewsCount = reviewsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load profile stats: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refresh() => _load();

  Future<void> _handleLogout() async {
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ClientEditProfileScreen(),
      ),
    ).then((updated) {
      if (updated == true) {
        _refresh();
      }
    });
  }

  void _showEditPasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ubah Password", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan password baru (Min. 6 karakter)", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password Baru", prefixIcon: Icon(Icons.lock_outline)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter!'), backgroundColor: Colors.red),
                );
                return;
              }
              final newPassword = passwordController.text;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() => _isLoading = true);
              final success = await context.read<AuthCubit>().updatePassword(newPassword: newPassword);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal ubah password.'), backgroundColor: Colors.red),
                );
              }
              if (mounted) setState(() => _isLoading = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFC84B20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.15,
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Wujudkan Bangunan Impian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Siap Memulai Proyek Baru?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hubungkan ide Anda dengan Kontraktor & Arsitek profesional terbaik di BuildMatch.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateProjectScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buat Proyek Sekarang',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      sliver: SliverToBoxAdapter(
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : _supabase.auth.currentUser;
        final userName = user?.userMetadata?['name'] ?? 'Klien';
        final userEmail = user?.email ?? '';

        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  name: userName,
                  email: userEmail,
                  avatarUrl: user?.userMetadata?['avatar_url'] as String?,
                  onEditPressed: _navigateToEditProfile,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: ProfileStatsRow(
                    activeProjectsCount: _activeProjectsCount,
                    completedProjectsCount: _completedProjectsCount,
                    reviewsCount: _reviewsCount,
                  ),
                ),
              ),
              _buildSectionTitle("Proyek Saya"),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ProfileProjectsList(
                    projects: _projects,
                    onRefresh: _refresh,
                  ),
                ),
              ),
              _buildPromoCard(context),
              _buildSectionTitle("Pengaturan Akun"),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ProfileSettingsCard(
                    onEditPassword: _showEditPasswordDialog,
                    onNotification: () {},
                    onHelp: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungi Customer Service...')));
                    },
                    onTerms: () {},
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                sliver: SliverToBoxAdapter(
                  child: TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        );
      },
    );
  }
}
