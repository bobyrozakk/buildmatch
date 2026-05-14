import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/glass_card.dart';
import '../../../core/constants/colors.dart';

class KontraktorHomeTab extends StatelessWidget {
  const KontraktorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['name'] ?? 'Kontraktor';
    final company = user?.userMetadata?['company_name'] ?? 'Vendor BuildMatch';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.architecture_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('BuildMatch Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // HERO CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat datang,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(company, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Text('Akun Terverifikasi', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // STATISTIK GLASSMORPHISM
                Row(
                  children: [
                    Expanded(child: _buildGlassStat('3', 'Proyek Aktif', Icons.handshake_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGlassStat('12', 'Selesai', Icons.task_alt_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildGlassStat('4.9', 'Rating', Icons.star_rounded)),
                  ],
                ),
                const SizedBox(height: 30),

                // PINTASAN AKSI
                const Text('Pintasan Aksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: IOSGlassCard(
                        blur: 15,
                        child: ListTile(
                          leading: const Icon(Icons.search_rounded, color: AppColors.primary),
                          title: const Text("Cari Tender", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onTap: () {}, // Nanti arahin ke tab Proyek
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: IOSGlassCard(
                        blur: 15,
                        child: ListTile(
                          leading: const Icon(Icons.folder_shared_rounded, color: AppColors.primary),
                          title: const Text("Update Portofolio", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          onTap: () {}, 
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStat(String value, String label, IconData icon) {
    return IOSGlassCard(
      blur: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}