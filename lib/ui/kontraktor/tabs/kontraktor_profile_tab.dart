import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/vendor_provider.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/certification_model.dart';
import '../screens/kontraktor_profileEdit_screen.dart';
import '../../shared/widgets/glass_card.dart';
import '../../../core/constants/colors.dart';

// UBAH JADI STATEFUL WIDGET BIAR BISA REFRESH
class KontraktorProfileTab extends StatefulWidget {
  const KontraktorProfileTab({super.key});

  @override
  State<KontraktorProfileTab> createState() => _KontraktorProfileTabState();
}

class _KontraktorProfileTabState extends State<KontraktorProfileTab> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    _dataFuture = Future.wait([
      provider.fetchVendorProfile(),
      provider.fetchPortfolios(),
      provider.fetchCertifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: FutureBuilder(
        future: _dataFuture,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final profile = snapshot.data?[0] as ProfileModel?;
          final portfolios = snapshot.data?[1] as List<PortfolioModel>? ?? [];
          final certifications = snapshot.data?[2] as List<CertificationModel>? ?? [];

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

  Widget _buildHeader(BuildContext context, ProfileModel? profile) {
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
                    backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                    child: profile?.avatarUrl == null ? const Icon(Icons.person, size: 35, color: AppColors.primary) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.name ?? 'Vendor Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(profile?.companyName ?? 'Nama Perusahaan', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        if (profile?.isVerified == true)
                          const Text('✓ Terverifikasi', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: AppColors.primary),
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

  Widget _buildPortoCard(PortfolioModel data) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        image: data.imageUrl != null ? DecorationImage(image: NetworkImage(data.imageUrl!), fit: BoxFit.cover) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(data.year, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      ),
    );
  }

  Widget _buildSertifCard(CertificationModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(data.issuer, style: const TextStyle(fontSize: 11, color: Colors.black54)),
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