import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/project_provider.dart';
import '../../core/utils/glass_card.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text("My Projects"), centerTitle: false, elevation: 0),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: provider.fetchProjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IOSGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            _buildStatusTag(item['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['location'] ?? 'No Location', style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (item['progress_percent'] ?? 0) / 100,
                          backgroundColor: Colors.black12,
                          color: const Color(0xFF2B5C8F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusTag(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'open' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status?.toUpperCase() ?? 'OPEN',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'open' ? Colors.orange : Colors.green),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada proyek nih.", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
          const Text("Mulai buat proyek pertamamu di Beranda", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}