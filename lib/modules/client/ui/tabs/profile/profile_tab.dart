import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/providers/auth_provider.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/ui/auth/login_screen.dart';
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
    final prov = Provider.of<ProjectProvider>(context, listen: false);
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await prov.fetchClientProjectsWithContractor();
      
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
      final provider = Provider.of<AuthProvider>(context, listen: false);
      await provider.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showEditProfileDialog() {
    final user = _supabase.auth.currentUser;
    final nameController = TextEditingController(text: user?.userMetadata?['name'] ?? '');
    final phoneController = TextEditingController(text: user?.userMetadata?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap", prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "No. Telepon", prefixIcon: Icon(Icons.phone_outlined)),
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
              final newName = nameController.text;
              final newPhone = phoneController.text;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() => _isLoading = true);
              try {
                await _supabase.auth.updateUser(UserAttributes(data: {'name': newName, 'phone': newPhone}));
                if (user != null) {
                  await _supabase.from('profiles').update({'name': newName, 'phone': newPhone}).eq('id', user.id);
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal update profil.'), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
              try {
                await _supabase.auth.updateUser(UserAttributes(password: newPassword));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: Colors.green),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal ubah password.'), backgroundColor: Colors.red),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
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

    final user = _supabase.auth.currentUser;
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
              onEditPressed: _showEditProfileDialog,
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
  }
}
