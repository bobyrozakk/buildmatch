import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class DetailPortofolioArsitekScreen extends StatelessWidget {
  final Map<String, dynamic>? portfolioData;
  const DetailPortofolioArsitekScreen({super.key, this.portfolioData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Portofolio',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArchitectHeader(),
                _buildImageGallery(),
                _buildTitleAndTags(),
                _buildSpesifikasi(),
                _buildDeskripsi(),
                _buildRatingUlasan(),
              ],
            ),
          ),
          // We don't render the main bottom nav bar here as this is a pushed screen.
          // But we render the floating action bar "Hubungi Arsitek".
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFloatingBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budi Santoso',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Text('Arsitek Tersertifikasi', style: TextStyle(color: Colors.black54, fontSize: 10)),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: Colors.amber, size: 10),
                    SizedBox(width: 2),
                    Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 28),
            ),
            child: const Text('Ikuti', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      children: [
        Stack(
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Icon(Icons.home, color: AppColors.primary, size: 12),
                    SizedBox(width: 4),
                    Text('Minimalis', style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Image.network(
                'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400&q=80',
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Image.network(
                'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=400&q=80',
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=400&q=80',
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: const Text('+4 Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleAndTags() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Small House Design\n22×26 Feet',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87, height: 1.2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFDECE4), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: const [
                    Text('Estimasi Biaya', style: TextStyle(color: Colors.black54, fontSize: 9)),
                    SizedBox(height: 2),
                    Text('Rp 84,4 Jt', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagItem(Icons.architecture, 'Minimalis'),
              _buildTagItem(Icons.square_foot, 'Luas: 57.2 m²'),
              _buildTagItem(Icons.location_on, 'Bali'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF7EFE7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpesifikasi() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spesifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpecCard(Icons.layers, 'Lantai', '2 Lantai')),
              const SizedBox(width: 12),
              Expanded(child: _buildSpecCard(Icons.king_bed, 'Kamar Tidur', '3 Kamar')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpecCard(Icons.bathtub, 'Kamar Mandi', '2 Kamar')),
              const SizedBox(width: 12),
              Expanded(child: _buildSpecCard(Icons.straighten, 'Ukuran', '22×26 ft')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeskripsi() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.5),
              children: [
                TextSpan(text: 'Desain rumah mungil 2 lantai yang memaksimalkan lahan terbatas dengan gaya arsitektur minimalis tropis. Sangat cocok untuk keluarga kecil yang menginginkan hunian modern dengan sirkulasi... '),
                TextSpan(text: 'Selengkapnya', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingUlasan() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Rating & Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF7EFE7), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Column(
                  children: [
                    const Text('4.8', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.primary)),
                    Row(
                      children: List.generate(5, (index) => Icon(Icons.star, color: index < 4 ? Colors.amber : Colors.amber.shade200, size: 12)),
                    ),
                    const SizedBox(height: 4),
                    const Text('124 Ulasan', style: TextStyle(color: AppColors.primary, fontSize: 9)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, 0.8),
                      _buildRatingBar(4, 0.2),
                      _buildRatingBar(3, 0.05),
                      _buildRatingBar(2, 0),
                      _buildRatingBar(1, 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildUlasanItem(),
          const SizedBox(height: 24),
          const Center(
            child: Text('Beri Rating Desain Ini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.star_border, color: Colors.black26, size: 28),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white,
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUlasanItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Siti Aminah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
                Text('2 hari yang lalu', style: TextStyle(color: Colors.black45, fontSize: 9)),
              ],
            ),
            const Spacer(),
            Row(
              children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 10)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Desainnya sangat fungsional! Ruangannya terasa lega meskipun ukurannya kecil. Arsiteknya juga sangat kooperatif saat ditanya.',
          style: TextStyle(color: Colors.black54, fontSize: 10, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFloatingBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite_border, color: Colors.black54, size: 24),
                SizedBox(height: 2),
                Text('248', style: TextStyle(color: Colors.black54, fontSize: 9)),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bookmark_border, color: Colors.black54, size: 24),
                SizedBox(height: 2),
                Text('Simpan', style: TextStyle(color: Colors.black54, fontSize: 9)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                label: const Text('Hubungi Arsitek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F2A0C), // Dark red/brown button from Figma
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
