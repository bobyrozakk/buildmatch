import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/data/models/profile_model.dart';
import 'package:buildmatch/data/providers/architect_provider.dart';
import 'package:buildmatch/modules/client/logic/chat/chat_cubit.dart';
import 'package:buildmatch/ui/shared/screens/chat_detail_screen.dart';
import 'widgets/architect_stat_pill.dart';
import 'widgets/architect_spec_chip.dart';
import 'widgets/architect_portfolio_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final chatCubit = context.read<ChatCubit>();

    // Cek apakah sudah ada chat yang accepted
    final existingAccepted = chatCubit.chats.where((c) =>
        (c.clientId == profile.id || c.vendorId == profile.id)).toList();
    final isExistingAccepted = existingAccepted.isNotEmpty;

    final chatId = await chatCubit.getOrCreateChat(profile.id);

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
    final location = widget.architectData['location'] as String? ?? '';
    final specs = widget.architectData['specializations'] as Map<String, dynamic>? ?? {};
    final styles = List<String>.from(specs['styles'] ?? []);
    final projectTypes = List<String>.from(specs['project_types'] ?? []);
    final technicalSkills = List<String>.from(specs['technical_skills'] ?? []);

    final displayName = profile.name.isNotEmpty
        ? profile.name
        : (profile.role == 'vendor' ? 'Kontraktor' : 'Arsitek');
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
                          color: Colors.white.withValues(alpha: 0.05),
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
                          color: Colors.white.withValues(alpha: 0.05),
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
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                                 if (profile.role == 'vendor' && profile.nib != null && profile.nib!.isNotEmpty)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 2.0),
                                     child: Text(
                                       'NIB: ${profile.nib!}',
                                       style: const TextStyle(color: Colors.white60, fontSize: 12),
                                     ),
                                   ),
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
                      if (profile.role == 'architect' && experience.isNotEmpty) ...[
                        ArchitectStatPill(
                          icon: Icons.work_outline_rounded,
                          value: '$experience thn',
                          label: 'Pengalaman',
                        ),
                        const SizedBox(width: 10),
                      ],
                      ArchitectStatPill(
                        icon: Icons.verified_outlined,
                        value: profile.isVerified ? 'Terverifikasi' : 'Belum',
                        label: 'Status',
                      ),
                      if (profile.role == 'vendor' && profile.phone != null && profile.phone!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        ArchitectStatPill(
                          icon: Icons.phone_android_rounded,
                          value: profile.phone!,
                          label: 'Kontak',
                        ),
                      ],
                    ],
                  ),

                  if (profile.role == 'architect') ...[
                    if (styles.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Gaya Desain', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: styles.map((s) => ArchitectSpecChip(label: s, color: AppColors.primary)).toList(),
                      ),
                    ],

                    if (projectTypes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Jenis Proyek', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: projectTypes.map((s) => ArchitectSpecChip(label: s, color: Colors.teal.shade700)).toList(),
                      ),
                    ],

                    if (technicalSkills.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Keahlian Teknis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: technicalSkills.map((s) => ArchitectSpecChip(label: s, color: Colors.blueGrey.shade700)).toList(),
                      ),
                    ],
                  ],

                  // Dynamic Certifications list (Only shown for contractors/vendors)
                  if (profile.role == 'vendor')
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client
                          .from('certifications')
                          .select()
                          .eq('vendor_id', profile.id)
                          .then((res) => List<Map<String, dynamic>>.from(res)),
                      builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final certs = snapshot.data ?? [];
                      if (certs.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Sertifikasi / Berkas Pendukung',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: certs.length,
                            itemBuilder: (context, idx) {
                              final cert = certs[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade100),
                                ),
                                elevation: 0,
                                color: Colors.white,
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.primary),
                                  title: Text(cert['title'] ?? 'Sertifikasi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text(cert['issuer'] ?? '', style: const TextStyle(fontSize: 11)),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

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
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
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
                      final area = porto['area'] as double? ?? 0.0;

                      return ArchitectPortfolioCard(
                        title: title,
                        imgUrl: imgUrl,
                        style: style,
                        area: area,
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
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
}
