import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/project_provider.dart';
import '../screens/kontraktor_profileEdit_screen.dart'; // Sesuaikan path
import '../../shared/widgets/glass_card.dart';

// UBAH JADI STATEFUL WIDGET BIAR BISA REFRESH
class KontraktorProfileTab extends StatefulWidget {
  const KontraktorProfileTab({super.key});

  @override
  State<KontraktorProfileTab> createState() => _KontraktorProfileTabState();
}

class _KontraktorProfileTabState extends State<KontraktorProfileTab> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: FutureBuilder(
        // Ambil 3 data sekaligus biar efisien
        future: Future.wait([
          provider.fetchVendorProfile(),
          provider.fetchPortfolios(),
          provider.fetchCertifications(),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B2B0F)));
          }

          final profile = snapshot.data?[0] as Map<String, dynamic>?;
          final portfolios = snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
          final certifications = snapshot.data?[2] as List<Map<String, dynamic>>? ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER
              SliverToBoxAdapter(
                child: _buildHeader(context, profile),
              ),

              // STATS
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: _buildStatsRow(portfolios.length),
                ),
              ),

              // PORTOFOLIO SECTION
              _buildSectionTitle("Portofolio Karyamu"),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: portfolios.isEmpty 
                    ? _buildEmptyState("Belum ada portofolio")
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: portfolios.length,
                        itemBuilder: (context, i) => _buildPortoCard(portfolios[i]),
                      ),
                ),
              ),

              // SERTIFIKASI SECTION
              _buildSectionTitle("Sertifikasi & Keahlian"),
              certifications.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState("Belum ada sertifikat"))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildSertifCard(certifications[i]),
                        childCount: certifications.length,
                      ),
                    ),
                  ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? profile) {
    return Stack(
      children: [
        Container(height: 120, decoration: const BoxDecoration(color: Color(0xFF8B2B0F))),
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
                    backgroundColor: const Color(0xFFEFEBE4),
                    backgroundImage: profile?['avatar_url'] != null ? NetworkImage(profile!['avatar_url']) : null,
                    child: profile?['avatar_url'] == null ? const Icon(Icons.person, size: 35, color: Color(0xFF8B2B0F)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?['name'] ?? 'Vendor Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(profile?['company_name'] ?? 'Nama Perusahaan', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        if (profile?['is_verified'] == true)
                          const Text('✓ Terverifikasi', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Color(0xFF8B2B0F)),
                    onPressed: () async {
                      // KUNCI REFRESH ADA DI SINI
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      setState(() {}); // Panggil build ulang setelah balik dari edit screen
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int portoCount) {
    return Row(
      children: [
        _buildStatItem("$portoCount", "Proyek"),
        const SizedBox(width: 12),
        _buildStatItem("4.9", "Rating"),
        const SizedBox(width: 12),
        _buildStatItem("Aktif", "Status"),
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
            Text(val, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8B2B0F))),
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

  Widget _buildPortoCard(Map<String, dynamic> data) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        image: data['image_url'] != null ? DecorationImage(image: NetworkImage(data['image_url']), fit: BoxFit.cover) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['title'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(data['year'], style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      ),
    );
  }

  Widget _buildSertifCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Color(0xFF8B2B0F)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(data['issuer'], style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ])),
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)));
  }
}