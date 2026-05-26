import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class DetailDesainScreen extends StatelessWidget {
  final Map<String, dynamic>? designData;
  const DetailDesainScreen({super.key, this.designData});

  @override
  Widget build(BuildContext context) {
    final title = designData?['title'] ?? 'The Terracotta Pavilion';
    final imageUrl = designData?['image_url'] ?? 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/modern_villa.jpg';
    final likesStr = designData?['likes'] ?? '4.8';
    // Remove the 'k' if present and convert to a rating format for now, or just use 4.8
    final rating = likesStr.contains('k') ? '4.8' : '4.5';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5C1C08), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Desain', style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF5C1C08), size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF5C1C08), size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // spacing for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8F2A0C), // Reddish brown
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                const Text('Kode: ARCH-2023-089', style: TextStyle(color: Colors.black54, fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFD97706), size: 16), // Orange star
                                  const SizedBox(width: 4),
                                  Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                ],
                              ),
                              const Text('12 Ulasan', style: TextStyle(color: Colors.black45, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Features Grid
                      Row(
                        children: [
                          _buildFeatureCard(Icons.layers_outlined, 'Lantai', '2 Tingkat'),
                          const SizedBox(width: 12),
                          _buildFeatureCard(Icons.bed_outlined, 'Kamar', '3 Ruang'),
                          const SizedBox(width: 12),
                          _buildFeatureCard(Icons.square_foot_outlined, 'Luas', '180 m²'),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Deskripsi
                      const Text('Deskripsi Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 12),
                      const Text(
                        'Desain ini memadukan material bata ekspos lokal dengan struktur baja modern. Fokus utama adalah sirkulasi udara alami dan pencahayaan maksimal melalui atrium tengah yang memberikan kesan luas dan sejuk di iklim tropis Indonesia.',
                        style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Riwayat Pengiriman
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Riwayat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          Row(
                            children: const [
                              Text('Kirim Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8F2A0C))),
                              Icon(Icons.play_arrow, color: Color(0xFF8F2A0C), size: 14),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            _buildHistoryCard(
                              'Budi Santoso',
                              'Diterima 12 Jun',
                              'Terkonfirmasi',
                              const Color(0xFFD1FAE5), // Light green
                              const Color(0xFF065F46), // Dark green text
                              'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg',
                            ),
                            const SizedBox(width: 16),
                            _buildHistoryCard(
                              'Siti Aminah',
                              'Diterima 10 Jun',
                              'Menunggu',
                              const Color(0xFFFDE68A), // Light yellow
                              const Color(0xFF92400E), // Dark yellow text
                              'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Rating & Ulasan
                      const Text('Rating & Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 16),
                      
                      // Review 1
                      _buildReviewCard(
                        'Budi Santoso',
                        'BS',
                        '2 hari yang lalu',
                        5,
                        'Desainnya sangat detail dan arsiteknya sangat komunikatif. Material yang disarankan juga sangat masuk akal dengan budget saya. Sangat puas!',
                      ),
                      const SizedBox(height: 16),
                      
                      // Review 2
                      _buildReviewCardWithReply(
                        'Anton Wijaya',
                        'AW',
                        '1 minggu yang lalu',
                        4,
                        'Konsep fasadnya sangat menarik. Sedikit catatan untuk area servis mungkin bisa dioptimalkan lagi, tapi secara keseluruhan sangat bagus.',
                        'Anda (Arsitek)',
                        '5 hari yang lalu',
                        'Terima kasih Pak Anton, kami akan revisi bagian area servis sesuai masukan Bapak.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Lihat\nStatistik', textAlign: TextAlign.center, style: TextStyle(height: 1.2)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF8F2A0C)),
                          foregroundColor: const Color(0xFF8F2A0C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_square, size: 18, color: Colors.white),
                        label: const Text('Edit Desain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F2A0C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5DCD3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8F2A0C), size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(String name, String date, String status, Color statusBg, Color statusText, String avatarUrl) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatarUrl),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                Text(date, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: TextStyle(color: statusText, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    const Icon(Icons.more_vert, size: 14, color: Colors.black45),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String initials, String date, int rating, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF3EBE3),
                child: Text(initials, style: const TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Row(
                      children: List.generate(5, (index) => Icon(Icons.star, size: 12, color: index < rating ? const Color(0xFFD97706) : Colors.grey.shade300)),
                    ),
                  ],
                ),
              ),
              Text(date, style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.reply, size: 16, color: Color(0xFF8F2A0C)),
                SizedBox(width: 4),
                Text('Balas', style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCardWithReply(String name, String initials, String date, int rating, String text, String replyName, String replyDate, String replyText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF3EBE3),
                child: Text(initials, style: const TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Row(
                      children: List.generate(5, (index) => Icon(Icons.star, size: 12, color: index < rating ? const Color(0xFFD97706) : Colors.grey.shade300)),
                    ),
                  ],
                ),
              ),
              Text(date, style: const TextStyle(fontSize: 10, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          
          // Reply Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EBE3),
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: Color(0xFF8F2A0C), width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(replyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8F2A0C))),
                    Text(replyDate, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(replyText, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.reply, size: 16, color: Colors.black38),
                SizedBox(width: 4),
                Text('Sudah Dibalas', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
