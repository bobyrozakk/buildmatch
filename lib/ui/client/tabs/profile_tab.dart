import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/auth_provider.dart';
import '../../auth/role_screen.dart'; 

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- LOGIC: LOGOUT ---
  void _handleLogout() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    await provider.logout();
    
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
      (route) => false,
    );
  }

  // --- LOGIC: EDIT PROFILE ---
  void _showEditProfileDialog() {
    final user = _supabase.auth.currentUser;
    final currentName = user?.userMetadata?['name'] ?? '';
    final currentPhone = user?.userMetadata?['phone'] ?? '';

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (dialogContext) { 
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal", style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              onPressed: () async {
                // 1. Simpan nilai dari textfield DULU
                final newName = nameController.text;
                final newPhone = phoneController.text;

                // 2. Tutup dialognya
                Navigator.pop(dialogContext);
                
                // 3. Mulai proses loading
                if (!mounted) return;
                setState(() => _isLoading = true);
                
                try {
                  // Update di Auth Metadata
                  await _supabase.auth.updateUser(UserAttributes(
                    data: {'name': newName, 'phone': newPhone},
                  ));
                  
                  // Update di Tabel Profiles
                  if (user != null) {
                    await _supabase.from('profiles').update({
                      'name': newName,
                      'phone': newPhone,
                    }).eq('id', user.id);
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal update profil.'), backgroundColor: Colors.red));
                } finally {
                  // 4. Pastikan loading berhenti & layar ter-refresh
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2B0F)),
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIC: UBAH PASSWORD ---
  void _showEditPasswordDialog() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) { // <-- Pakai dialogContext
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Ubah Password", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Masukkan password baru Anda (Min. 6 karakter)", style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password Baru", prefixIcon: Icon(Icons.lock_outline)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal", style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter!'), backgroundColor: Colors.red));
                  return;
                }
                
                final newPassword = passwordController.text;
                Navigator.pop(dialogContext);
                
                if (!mounted) return;
                setState(() => _isLoading = true);
                
                try {
                  await _supabase.auth.updateUser(UserAttributes(password: newPassword));
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal ubah password.'), backgroundColor: Colors.red));
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B2B0F)),
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Klien';
    final userEmail = user?.email ?? '';
    
    // Ambil inisial nama untuk avatar
    String initials = "BS";
    if (userName.isNotEmpty && userName != 'Klien') {
      List<String> nameParts = userName.split(" ");
      if (nameParts.length > 1) {
        initials = nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
      } else {
        initials = userName.substring(0, userName.length > 1 ? 2 : 1).toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Background cream
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B2B0F)))
        : SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // --- HEADER: AVATAR & INFO ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFEFEBE4), shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 18, color: Color(0xFF8B2B0F)),
                          ),
                          onPressed: _showEditProfileDialog,
                        ),
                      ),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFEFEBE4),
                            child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                          ),
                          const SizedBox(height: 12),
                          Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(userEmail, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFEFEBE4), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.shield_outlined, size: 14, color: Color(0xFF8B2B0F)),
                                SizedBox(width: 6),
                                Text("Member Sejak 2026", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- STATS ROW ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("2", "Proyek Aktif")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("3", "Proyek Selesai")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("4", "Ulasan\nDiberikan")),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- PROYEK SAYA (Dummy UI Sesuai Figma) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Proyek Saya", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text("Lihat Semua", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        _buildProjectItem(Icons.home_rounded, "Renovasi Rumah Induk", "PT Bangun Jaya", "Selesai", Colors.green),
                        _buildDivider(),
                        _buildProjectItem(Icons.architecture_rounded, "Desain Interior Dapur", "Studio Arsitek A", "Berjalan", const Color(0xFFD85A31)),
                        _buildDivider(),
                        _buildProjectItem(Icons.business_rounded, "Pembangunan Pagar", "CV Karya Mandiri", "Menunggu", Colors.grey.shade600),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- PENGATURAN AKUN ---
                  const Align(alignment: Alignment.centerLeft, child: Text("Pengaturan Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        _buildSettingItem(Icons.lock_outline, "Ubah Password", onTap: _showEditPasswordDialog),
                        _buildDivider(),
                        _buildSettingItem(Icons.notifications_none_rounded, "Notifikasi", onTap: () {}), // UI Only
                        _buildDivider(),
                        _buildSettingItem(Icons.help_outline_rounded, "Bantuan & FAQ", onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menghubungi Customer Service...')));
                        }),
                        _buildDivider(),
                        _buildSettingItem(Icons.description_outlined, "Syarat & Ketentuan", onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- LOGOUT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFF8B2B0F)),
                      label: const Text("Keluar dari Akun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.transparent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("BuildMatch v1.0.0", style: TextStyle(fontSize: 12, color: Colors.black38)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFFEFEBE4), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF8B2B0F))),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProjectItem(IconData icon, String title, String subtitle, String status, Color statusColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color(0xFFF7F4EF), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF8B2B0F), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFF7F4EF), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF8B2B0F), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
    );
  }
}