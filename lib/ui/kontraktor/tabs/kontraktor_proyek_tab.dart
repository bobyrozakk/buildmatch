import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/data/models/project_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../screens/kontraktor_detail_proyek_screen.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

class KontraktorProyekTab extends StatefulWidget {
  const KontraktorProyekTab({super.key});

  @override
  State<KontraktorProyekTab> createState() => _KontraktorProyekTabState();
}

class _KontraktorProyekTabState extends State<KontraktorProyekTab> {
  late Future<List<ProjectModel>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = Provider.of<ProjectProvider>(context, listen: false).fetchAvailableProjects();
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
                child: FutureBuilder<List<ProjectModel>>(
                      future: _projectsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                            final clientName = p.clientName ?? 'Klien';
                            
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
                                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text("Budget: ${AppFormatters.formatRupiah(p.budget)}", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(p.location ?? 'Lokasi tidak diketahui', style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                                              backgroundColor: AppColors.primary,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}