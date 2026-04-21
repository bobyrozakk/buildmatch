import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/glass_card.dart';
import '../../data/providers/project_provider.dart';

class ContractorTab extends StatelessWidget {
  const ContractorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)], // Pastel gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Text(
                  "Mitra Kontraktor",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              
              // SEARCH BAR (UI ONLY UNTUK MVP)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: IOSGlassCard(
                  blur: 15,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari nama kontraktor...",
                      hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFB53D1B)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // LIST VENDOR DARI SUPABASE
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: provider.fetchVendors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFB53D1B)));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final vendors = snapshot.data!;

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: vendors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final vendor = vendors[index];
                        return _buildVendorCard(vendor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    return IOSGlassCard(
      blur: 20,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // FOTO PROFIL (Dummy pakai UI ui-avatars karena DB belum ada image_url)
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: NetworkImage(
                'https://ui-avatars.com/api/?name=${vendor['name']}&background=B53D1B&color=fff&size=128',
              ),
            ),
            const SizedBox(width: 16),
            
            // INFO VENDOR
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor['name'] ?? 'Kontraktor Tanpa Nama',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Spesialis Konstruksi & Renovasi", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const Text(" 4.9", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(Icons.phone, color: Colors.black38, size: 14),
                      Text(" ${vendor['phone'] ?? 'Tidak ada No. HP'}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada Mitra Kontraktor", style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
          const Text("Sistem sedang menunggu kontraktor bergabung.", style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}