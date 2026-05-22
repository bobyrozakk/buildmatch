import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/glass_card.dart';
import '../screens/create_project_screen.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/models/project_model.dart';
import '../../../core/constants/colors.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  /// Cek draft user. Jika ada, tampilkan dialog pilihan.
  /// Jika tidak ada, langsung buka form baru.
  Future<void> _onMulaiProyek() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final drafts = await provider.fetchDraftProjects();

    if (!mounted) return;

    if (drafts.isEmpty) {
      // Tidak ada draft — langsung buka form baru
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      );
      return;
    }

    // Ada draft — tampilkan dialog pilihan
    final ProjectModel latestDraft = drafts.first;
    final String draftTitle = latestDraft.title.isNotEmpty &&
            latestDraft.title != 'Draft Tanpa Judul'
        ? latestDraft.title
        : 'Draft Tanpa Judul';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ada Draft yang Belum Selesai',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kamu punya proyek yang belum dipublikasikan:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      draftTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (drafts.length > 1) ...[  
              const SizedBox(height: 6),
              Text(
                '+ ${drafts.length - 1} draft lainnya di tab Progress',
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'new'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Buat Baru',
                style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lanjutkan Draft',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'continue') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProjectScreen(draft: latestDraft),
        ),
      );
    } else if (result == 'new') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Soft pastel blue-to-pink gradient background
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
                const SizedBox(height: 10),
                // 1. HEADER & NOTIFICATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selamat datang,",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          // Nama user dari auth metadata
                          Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? 'Klien',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.deepOrangeAccent,
                        ),
                        onPressed: () {
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. SEARCH BAR
                IOSGlassCard(
                  blur: 15,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari kontraktor, arsitek...",
                      hintStyle: const TextStyle(
                        color: Colors.black45,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                      ),
                      suffixIcon: const Icon(
                        Icons.tune_rounded,
                        color: Colors.deepOrangeAccent,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. HERO CARD (Mulai Proyek)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Bangun Rumah\nImpian Anda",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _onMulaiProyek,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Mulai Proyek",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 4. LAYANAN KAMI
                _buildSectionHeader("Layanan Kami"),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildServiceItem(
                      Icons.architecture_rounded,
                      "Kontraktor",
                      Colors.brown.shade600,
                    ),
                    _buildServiceItem(
                      Icons.design_services_rounded,
                      "Arsitek",
                      Colors.brown.shade600,
                    ),
                    _buildServiceItem(
                      Icons.calculate_rounded,
                      "Estimasi\nBiaya",
                      Colors.brown.shade600,
                    ),
                    _buildServiceItem(
                      Icons.chat_bubble_outline_rounded,
                      "Konsultasi",
                      Colors.brown.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 5. KONTRAKTOR TERPOPULER
                _buildSectionHeader("Kontraktor Terpopuler"),
                const SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    children: [
                      _buildContractorCard(
                        name: "PT Bangun Jaya",
                        specialty: "Rumah Tinggal",
                        location: "Malang",
                        rating: "4.8",
                        imageUrl: "https://i.pravatar.cc/150?img=11",
                      ),
                      const SizedBox(width: 16),
                      _buildContractorCard(
                        name: "CV Karya Mandiri",
                        specialty: "Interior & Eksterior",
                        location: "Surabaya",
                        rating: "4.9",
                        imageUrl: "https://i.pravatar.cc/150?img=5",
                      ),
                      const SizedBox(width: 16), // Padding ujung
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER BAWAH SINI ---

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Text(
          "Lihat Semua",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color iconColor) {
    return Column(
      children: [
        IOSGlassCard(
          blur: 20,
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildContractorCard({
    required String name,
    required String specialty,
    required String location,
    required String rating,
    required String imageUrl,
  }) {
    return IOSGlassCard(
      blur: 15,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar Profil + Rating
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(imageUrl),
                  backgroundColor: Colors.grey.shade300,
                ),
                Positioned(
                  right: -10,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nama & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blue, size: 14),
              ],
            ),
            const SizedBox(height: 4),
            // Spesialisasi
            Text(
              specialty,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
            const Spacer(),
            // Lokasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.black54,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
