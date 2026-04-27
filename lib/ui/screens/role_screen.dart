import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  int _selectedRole = 0; // 0: Client, 1: Kontraktor, 2: Arsitek

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Warna cream background Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {}, // Nanti diarahin ke Onboarding
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF8B2B0F), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.architecture, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text("BuildMatch", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text("Saya adalah...", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Pilih peran Anda untuk pengalaman\nyang lebih personal", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, height: 1.5)),
            const SizedBox(height: 40),

            // Opsi Role
            _buildRoleCard(0, "Client / Pemilik Rumah", "Cari kontraktor, buat proyek, pantau progres", Icons.home_rounded),
            const SizedBox(height: 16),
            _buildRoleCard(1, "Kontraktor", "Ajukan penawaran dan kelola proyek konstruksi", Icons.engineering_rounded),
            const SizedBox(height: 16),
            _buildRoleCard(2, "Arsitek", "Tampilkan portofolio dan terima kolaborasi proyek", Icons.architecture_rounded),

            const Spacer(),
            
            // Info Belum punya akun
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEFEBE4), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF8B2B0F), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                        children: [
                          TextSpan(text: "Belum mempunyai akun? daftar dengan cara "),
                          TextSpan(text: "klik disini", style: TextStyle(color: Color(0xFF8B2B0F), fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Lanjutkan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // MVP: Lanjut ke Login Client dulu apapun yg dipilih
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2B0F), // Terakota gelap Figma
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Lanjutkan ➔", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan kami", style: TextStyle(fontSize: 11, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(int index, String title, String desc, IconData icon) {
    bool isSelected = _selectedRole == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF8B2B0F) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3EBE1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF8B2B0F), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF8B2B0F) : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}