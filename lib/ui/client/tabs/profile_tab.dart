import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../../shared/widgets/glass_card.dart';
import '../../../core/constants/colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- ACTIONS ---

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

  // --- BUILD ---

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
          SliverToBoxAdapter(child: _buildHeader(userName, userEmail)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverToBoxAdapter(child: _buildStatsRow()),
          ),
          _buildSectionTitle("Proyek Saya"),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(child: _buildProjectCard()),
          ),
          _buildSectionTitle("Pengaturan Akun"),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(child: _buildSettingsCard()),
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

  // --- WIDGETS ---

  Widget _buildHeader(String name, String email) {
    return Stack(
      children: [
        Container(height: 120, decoration: const BoxDecoration(color: AppColors.primary)),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
          child: IOSGlassCard(
            blur: 20,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.cardCream,
                    child: Text(
                      _getInitials(name),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: AppColors.primary),
                    onPressed: _showEditProfileDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem("2", "Proyek Aktif"),
        const SizedBox(width: 12),
        _buildStatItem("3", "Selesai"),
        const SizedBox(width: 12),
        _buildStatItem("4", "Ulasan"),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
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

  Widget _buildProjectCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildProjectItem(Icons.home_rounded, "Renovasi Rumah Induk", "PT Bangun Jaya", "Selesai", Colors.green),
          _divider(),
          _buildProjectItem(Icons.architecture_rounded, "Desain Interior Dapur", "Studio Arsitek A", "Berjalan", const Color(0xFFD85A31)),
          _divider(),
          _buildProjectItem(Icons.business_rounded, "Pembangunan Pagar", "CV Karya Mandiri", "Menunggu", Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildProjectItem(IconData icon, String title, String subtitle, String status, Color statusColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: AppColors.backgroundCream, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildSettingItem(Icons.lock_outline, "Ubah Password", onTap: _showEditPasswordDialog),
          _divider(),
          _buildSettingItem(Icons.notifications_none_rounded, "Notifikasi", onTap: () {}),
          _divider(),
          _buildSettingItem(Icons.help_outline_rounded, "Bantuan & FAQ", onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungi Customer Service...')));
          }),
          _divider(),
          _buildSettingItem(Icons.description_outlined, "Syarat & Ketentuan", onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.backgroundCream, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Klien') return "BS";
    final parts = name.split(" ");
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }
}