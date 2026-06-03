import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/certification_model.dart';
import '../../../core/constants/colors.dart';
import '../screens/edit_profil_screen.dart';
import '../screens/upload_desain_screen.dart';
import '../screens/detail_portofolio_arsitek_screen.dart';
import '../../auth/login_screen.dart';


class ArsitekProfileTab extends StatefulWidget {
  const ArsitekProfileTab({super.key});

  @override
  State<ArsitekProfileTab> createState() => _ArsitekProfileTabState();
}

class _ArsitekProfileTabState extends State<ArsitekProfileTab> {
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final architect = Provider.of<ArchitectProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    
    _dataFuture = Future.wait([
      architect.fetchArchitectDetails(userId), // 0: profile
      architect.fetchPortfolios(userId),       // 1: portfolios
      architect.fetchArchitectStats(userId),   // 2: stats
      architect.fetchReviews(userId),          // 3: reviews
      architect.fetchCertifications(userId),   // 4: certifications
    ]);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _dataFuture;
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFCF8F5),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFF8F2A0C), size: 22),
            SizedBox(width: 10),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF8F2A0C),
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
              backgroundColor: const Color(0xFF8F2A0C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = context.read<AuthProvider>(); // simpan ref sebelum await
      await authProvider.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.hardware_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'Build',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary)),
                TextSpan(
                    text: 'Match',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
              ]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF8F2A0C), size: 22),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF8F2A0C),
        child: FutureBuilder<List<dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8F2A0C)));
            }

            final profileData = snapshot.data?[0] as Map<String, dynamic>?;
            final portfolios = snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
            final stats = snapshot.data?[2] as Map<String, dynamic>? ?? {};
            final reviews = snapshot.data?[3] as List<Map<String, dynamic>>? ?? [];
            final certsList = snapshot.data?[4] as List<CertificationModel>? ?? [];

            final profile = profileData?['profile'] as ProfileModel?;
            final bio = profileData?['bio'] as String? ?? "Belum ada bio.";
            
            final name = profile?.name.isNotEmpty == true ? profile!.name : "Arsitek";
            final String location;
            if (profileData != null && profileData['location'] != null && profileData['location'].toString().isNotEmpty) {
              location = profileData['location'].toString();
            } else {
              location = "Indonesia";
            }

            double totalRating = 0;
            for (final r in reviews) {
              totalRating += (r['rating'] as num?)?.toDouble() ?? 0.0;
            }
            final avgRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;
            final rating = avgRating.toStringAsFixed(1);
            final reviewsCount = reviews.length.toString();

            final finishedProjects = stats['portfolio_count']?.toString() ?? '0';
            final experienceYears = stats['experience_years']?.toString() ?? '0';
            final activeCollabs = stats['active_collabs']?.toString() ?? '0';
            final certificationCount = stats['cert_count']?.toString() ?? '0';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar & Name Card
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE5DCD3), width: 1.5),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFFF3EBE3),
                                backgroundImage: profile?.avatarUrl != null 
                                    ? NetworkImage(profile!.avatarUrl!) 
                                    : null,
                                child: profile?.avatarUrl == null
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                        style: const TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 36),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _navigateToEditProfile,
                                child: const CircleAvatar(
                                  backgroundColor: Color(0xFF8F2A0C),
                                  radius: 14,
                                  child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        
                        // Edit Profil Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _navigateToEditProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C1C08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Edit Profil', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Bio
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        
                        // Rating & Location Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating ($reviewsCount Ulasan)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            Container(width: 1, height: 12, color: Colors.black26),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Row (4 Pink/Brown Cards)
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('TOTAL DESAIN', finishedProjects)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatItem('TAHUN PENGALAMAN', experienceYears)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('KOLABORASI', activeCollabs)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatItem('SERTIFIKASI', certificationCount)),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Spesialisasi Section
                  const Text('Spesialisasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 12),
                  _buildSpecializationsChips(profileData?['specializations']),
                  
                  const SizedBox(height: 28),
            
                  const Text('Portofolio Publik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  if (portfolios.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.design_services_outlined, size: 36, color: Colors.black38),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada portofolio yang diunggah.', 
                            style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic)
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: portfolios.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, i) {
                        final p = portfolios[i];
                        final title = p['title'] as String? ?? 'Desain Tanpa Judul';
                        final imageUrl = p['image_url'] as String? ?? 'https://via.placeholder.com/500';
                        final style = p['style'] as String? ?? 'Modern';

                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPortofolioArsitekScreen(portfolioData: p),
                              ),
                            );
                            if (result == true && mounted) {
                              _refresh();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF3EBE3)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, fit: BoxFit.cover)
                                          : Container(color: const Color(0xFFFDF5EE)),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            style,
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month,
                                            size: 12,
                                            color: Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p['year']?.toString() ?? "2026",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if ((p['avg_rating'] as num?) != null && (p['avg_rating'] as num) > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star, size: 10, color: Color(0xFFD97706)),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    (p['avg_rating'] as num).toDouble().toStringAsFixed(1),
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Bottom Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final newProject = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UploadDesainScreen()),
                        );
                        if (newProject != null && newProject is Map<String, dynamic> && mounted) {
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text('Tambah Portofolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C1C08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
            
            const SizedBox(height: 32),
            
            // Sertifikasi & Lisensi Section
            const Text('Sertifikasi & Lisensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            if (certsList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada sertifikasi terdaftar.',
                    style: TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...certsList.map((cert) {
                String regNo = cert.issuer;
                String expiry = '-';
                if (cert.issuer.startsWith('{')) {
                  try {
                    final data = jsonDecode(cert.issuer);
                    regNo = data['registration_number'] ?? '';
                    expiry = data['expiry_date'] ?? '-';
                  } catch (_) {}
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildCertificationCard(
                    title: cert.title,
                    subtitle: 'Nomor Registrasi: $regNo • Berlaku hingga $expiry',
                    iconData: Icons.badge_outlined,
                  ),
                );
              }).toList(),
            
            const SizedBox(height: 32),
            
            // Ulasan Klien Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ulasan Klien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                Row(
                  children: [
                    Text('$rating/5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                  ],
                ),
              ],
            ),
            const Text(
              'Kepuasan klien adalah prioritas utama kami', 
              style: TextStyle(color: Colors.black45, fontSize: 11, height: 1.5)
            ),
            const SizedBox(height: 16),
            
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.rate_review_outlined, size: 36, color: Colors.black38),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada ulasan dari klien.',
                      style: TextStyle(color: Colors.black54, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            else
              ...reviews.map((r) {
                final clientProfile = r['profiles'] as Map<String, dynamic>?;
                final project = r['projects'] as Map<String, dynamic>?;
                final clientName = clientProfile?['name'] as String? ?? 'Klien';
                final projectName = project?['title'] as String? ?? 'Proyek';
                final ratingVal = r['rating'] as int? ?? 5;
                final commentText = r['comment'] as String? ?? '';
                final createdAtStr = r['created_at'] != null 
                    ? _formatReviewDate(DateTime.tryParse(r['created_at'] as String))
                    : 'Baru saja';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildClientReviewCard(
                    initials: clientName.isNotEmpty ? clientName[0].toUpperCase() : 'K',
                    name: clientName,
                    project: 'Proyek: $projectName',
                    time: createdAtStr,
                    comment: '"$commentText"',
                    rating: ratingVal,
                  ),
                );
              }).toList(),
            
            const SizedBox(height: 16),
            
            // Lihat Semua Ulasan Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5C1C08)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Lihat Semua Ulasan', 
                  style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // ─── Tombol Logout ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFB71C1C), size: 18),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFFFF5F5),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      );
    },
   ),
  ),
 );
}

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5EE), // Light soft pink/brown
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5E4D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: const TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
          const SizedBox(height: 6),
          Text(
            value, 
            style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA07A).withOpacity(0.2), // Soft orange/peach
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFA07A).withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildPortfolioCard({
    required String imageUrl,
    required String title,
    required String category,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image with Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
          
          // Info Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                ),
                const SizedBox(height: 4),
                Text(
                  category, 
                  style: const TextStyle(color: Colors.black45, fontSize: 11)
                ),
                const SizedBox(height: 12),
                
                // Lihat Detail button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3EBE3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lihat Detail', 
                      style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard({
    required String title,
    required String subtitle,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5DCD3)),
            ),
            child: Icon(iconData, color: const Color(0xFF8F2A0C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, height: 1.3)
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle, 
                  style: const TextStyle(color: Colors.black45, fontSize: 10, height: 1.3)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientReviewCard({
    required String initials,
    required String name,
    required String project,
    required String time,
    required String comment,
    int rating = 5,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF3EBE3),
                radius: 18,
                child: Text(
                  initials, 
                  style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.orange,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(project, style: const TextStyle(color: Colors.black45, fontSize: 10)),
                  ],
                ),
              ),
              Text(time, style: const TextStyle(color: Colors.black38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsChips(Map<String, dynamic>? specializations) {
    if (specializations == null) {
      return const Text('Belum ditentukan', style: TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic));
    }
    
    final List<String> allTags = [];
    if (specializations['styles'] != null) {
      allTags.addAll(List<String>.from(specializations['styles']));
    }
    if (specializations['project_types'] != null) {
      allTags.addAll(List<String>.from(specializations['project_types']));
    }
    if (specializations['technical_skills'] != null) {
      allTags.addAll(List<String>.from(specializations['technical_skills']));
    }

    if (allTags.isEmpty) {
      return const Text('Belum ditentukan', style: TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTags.map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  String _formatReviewDate(DateTime? date) {
    if (date == null) return "Baru saja";
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) {
      return "${date.day}/${date.month}/${date.year}";
    } else if (diff.inDays > 0) {
      return "${diff.inDays} hari lalu";
    } else if (diff.inHours > 0) {
      return "${diff.inHours} jam lalu";
    } else {
      return "Baru saja";
    }
  }
}
