import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/project_provider.dart';
import '../screens/project_detail_screen.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Warna Cream Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Proyek Saya", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: provider.fetchProjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8B2B0F)));
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final projects = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final item = projects[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: item)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item['title'] ?? 'Tanpa Judul', 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ),
                              _buildStatusTag(item['status']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text(item['location'] ?? 'Lokasi tidak set', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Progres Pembangunan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text("${item['progress_percent'] ?? 0}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (item['progress_percent'] ?? 0) / 100,
                              backgroundColor: const Color(0xFFEFEBE4),
                              color: const Color(0xFF8B2B0F),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusTag(String? status) {
    Color color = status == 'open' ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status?.toUpperCase() ?? 'OPEN',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada proyek nih.", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}