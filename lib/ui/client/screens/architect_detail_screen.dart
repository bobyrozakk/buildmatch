import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../shared/screens/chat_detail_screen.dart';

class ArchitectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> architectData;
  final bool openChat;

  const ArchitectDetailScreen({
    super.key,
    required this.architectData,
    this.openChat = false,
  });

  @override
  State<ArchitectDetailScreen> createState() => _ArchitectDetailScreenState();
}

class _ArchitectDetailScreenState extends State<ArchitectDetailScreen> {
  late Future<List<Map<String, dynamic>>> _portfolioFuture;
  bool _startingChat = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.architectData['profile'] as ProfileModel;
    _portfolioFuture = Provider.of<ArchitectProvider>(context, listen: false)
        .fetchPortfolios(profile.id);

    // Auto-open chat if flagged
    if (widget.openChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startChat());
    }
  }

  Future<void> _startChat() async {
    if (_startingChat) return;
    setState(() => _startingChat = true);

    final profile = widget.architectData['profile'] as ProfileModel;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Cek apakah sudah ada chat yang accepted
    final existingAccepted = chatProvider.chats.where((c) =>
        (c.clientId == profile.id || c.vendorId == profile.id)).toList();
    final isExistingAccepted = existingAccepted.isNotEmpty;

    final chatId = await chatProvider.getOrCreateChat(profile.id);

    setState(() => _startingChat = false);

    if (!mounted) return;

    if (chatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            receiverName: profile.name.isNotEmpty ? profile.name : 'Arsitek',
            receiverAvatar: profile.avatarUrl,
            receiverId: profile.id,
            // Jika chat baru (belum accepted), kasih tahu pending
            chatStatus: isExistingAccepted ? 'accepted' : 'pending',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka chat. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.architectData['profile'] as ProfileModel;
    final bio = widget.architectData['bio'] as String? ?? '';
    final location = widget.architectData['location'] as String? ?? '';
    final specs = widget.architectData['specializations'] as Map<String, dynamic>? ?? {};
    final styles = List<String>.from(specs['styles'] ?? []);
    final projectTypes = List<String>.from(specs['project_types'] ?? []);
    final technicalSkills = List<String>.from(specs['technical_skills'] ?? []);

    final displayName = profile.name.isNotEmpty ? profile.name : 'Arsitek';
    final studio = profile.companyName?.isNotEmpty == true ? profile.companyName! : '';
    final experience = profile.experienceYears ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar with hero image / gradient header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, Color(0xFF5C1C08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Hero(
                            tag: 'architect_avatar_${profile.id}',
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : NetworkImage(
                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=ffffff&color=8B2B0F&size=128',
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (profile.isVerified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 18),
                                    ],
                                  ],
                                ),
                                if (studio.isNotEmpty)
                                  Text(studio, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                if (location.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white54, size: 12),
                                      const SizedBox(width: 2),
                                      Text(location, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _buildStatPill(Icons.work_outline_rounded, '$experience thn', 'Pengalaman'),
                      const SizedBox(width: 10),
                      _buildStatPill(Icons.verified_outlined, profile.isVerified ? 'Terverifikasi' : 'Belum', 'Status'),
                    ],
                  ),

                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Tentang Saya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(bio, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5)),
                  ],

                  if (styles.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Gaya Desain', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: styles.map((s) => _buildChip(s, AppColors.primary)).toList(),
                    ),
                  ],

                  if (projectTypes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Jenis Proyek', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: projectTypes.map((s) => _buildChip(s, Colors.teal.shade700)).toList(),
                    ),
                  ],

                  if (technicalSkills.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Keahlian Teknis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: technicalSkills.map((s) => _buildChip(s, Colors.blueGrey.shade700)).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Portofolio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Portfolio grid
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _portfolioFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )),
                );
              }

              final portfolios = snap.data ?? [];
              if (portfolios.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 40, color: Colors.black26),
                        SizedBox(height: 8),
                        Text('Belum ada portofolio', style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final porto = portfolios[i];
                      final title = porto['title'] as String? ?? 'Portofolio';
                      final imgUrl = porto['image_url'] as String?;
                      final style = porto['style'] as String? ?? '';
                      final area = porto['area'] as double? ?? 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: imgUrl != null
                                  ? Image.network(imgUrl, width: double.infinity, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.cardCream,
                                        child: const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                                      ))
                                  : Container(
                                      color: AppColors.cardCream,
                                      child: const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (style.isNotEmpty)
                                        Flexible(child: Text(style, style: const TextStyle(fontSize: 10, color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      if (style.isNotEmpty && area > 0) const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.black38)),
                                      if (area > 0)
                                        Text('${area.toInt()} m²', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: portfolios.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // Bottom CTA
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: ElevatedButton.icon(
            onPressed: _startingChat ? null : _startChat,
            icon: _startingChat
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
            label: Text(
              _startingChat ? 'Membuka Chat...' : 'Mulai Konsultasi',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
