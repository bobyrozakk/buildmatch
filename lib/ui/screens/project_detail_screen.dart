import 'package:flutter/material.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Map<String, dynamic> project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text("Detail Proyek", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF8B2B0F)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fungsi Edit segera hadir!")));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Info Proyek
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2B0F),
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: NetworkImage(project['image_urls'] != null && project['image_urls'].isNotEmpty 
                      ? project['image_urls'][0] 
                      : 'https://via.placeholder.com/400x200'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                ),
              ),
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: const Text("LIVE TENDER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(project['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("Informasi Bangunan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Grid Detail
            Row(
              children: [
                _buildInfoChip(Icons.square_foot, "${project['building_size']} m²"),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.layers, "${project['floors']} Lantai"),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.bed, "${project['bedrooms']} Kamar"),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text("Daftar Penawaran (Bids)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // List Kontraktor yang ngebid (Dummy UI)
            _buildBidItem("PT. Bangun Jaya Konstruksi", "Rp 320.000.000", "4.8"),
            _buildBidItem("CV. Karya Mandiri", "Rp 345.000.000", "4.5"),
            
            const SizedBox(height: 24),
            // Tombol Batalkan Proyek
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                child: const Text("Batalkan Tender Proyek", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8B2B0F), size: 20),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBidItem(String name, String price, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFEFEBE4), child: Icon(Icons.person, color: Color(0xFF8B2B0F))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(color: Color(0xFF8B2B0F), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Column(
            children: [
              Row(children: [const Icon(Icons.star, color: Colors.orange, size: 14), Text(rating, style: const TextStyle(fontSize: 12))]),
              const Text("Lihat Detail", style: TextStyle(fontSize: 10, color: Colors.blue)),
            ],
          )
        ],
      ),
    );
  }
}