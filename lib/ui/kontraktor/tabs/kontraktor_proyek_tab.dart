import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import '../../shared/widgets/glass_card.dart'; 
import '../screens/kontraktor_detail_proyek_screen.dart';

class KontraktorProyekTab extends StatelessWidget {
  const KontraktorProyekTab({super.key});

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: const Text('Bursa Proyek (Tender)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              Expanded(
                child: Consumer<ProjectProvider>(
                  builder: (context, provider, _) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: provider.fetchAvailableProjects(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B2B0F)));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text("Belum ada proyek yang open tender."));
                        }

                        final projects = snapshot.data!;
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: projects.length,
                          itemBuilder: (context, i) {
                            final p = projects[i];
                            final clientName = p['profiles']?['name'] ?? 'Klien';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: IOSGlassCard(
                                blur: 15,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: const Color(0xFF8B2B0F).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text("Budget: ${_formatRupiah(p['budget']?.toDouble() ?? 0)}", style: const TextStyle(color: Color(0xFF8B2B0F), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(p['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(p['location'] ?? 'Lokasi tidak diketahui', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('👤 $clientName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          ElevatedButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => KontraktorDetailProyekScreen(project: p)),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF8B2B0F),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                            ),
                                            child: const Text('Lihat Detail', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
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
}