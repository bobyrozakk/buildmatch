import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../shared/screens/chat_detail_screen.dart';

class ArsitekInboxTab extends StatefulWidget {
  const ArsitekInboxTab({super.key});

  @override
  State<ArsitekInboxTab> createState() => _ArsitekInboxTabState();
}

class _ArsitekInboxTabState extends State<ArsitekInboxTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Dummy data for Permintaan Tab to allow state manipulation
  List<Map<String, dynamic>> permintaanList = [
    {
      'id': '1',
      'name': 'Rizky Pratama',
      'role': 'Client',
      'time': '11:00',
      'quote': 'Halo kak, saya mau konsultasi soal desain rumah 2 lantai minimalis...',
      'avatarUrl': 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg',
    },
    {
      'id': '2',
      'name': 'Dewi Anggraini',
      'role': 'Client',
      'time': '10:45',
      'quote': 'Pak saya tertarik dengan portofolio Bapak, bisa diskusi dulu?',
      'avatarUrl': 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg',
    },
    {
      'id': '3',
      'name': 'Farhan Hidayat',
      'role': 'Client',
      'time': 'Kemarin',
      'quote': 'Butuh arsitek buat proyek ruko 3 lantai, apakah Bapak available?',
      'avatarUrl': 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 24),
          onPressed: () {},
        ),
        title: const Text(
          'BuildMatch',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 24),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Pesan'),
            Tab(text: 'Permintaan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPesanTab(),
          _buildPermintaanTab(),
        ],
      ),
    );
  }

  Widget _buildPesanTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black45, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Cari percakapan...',
                      hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildChatItem(
                  name: 'Budi Santoso',
                  message: 'Pak, revisi desain struktur lantai 2 sudah saya kirim...',
                  time: '10:45',
                  avatarUrl: 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg',
                  unreadCount: 2,
                  isActive: true,
                ),
                _buildChatItem(
                  name: 'Siti Aminah',
                  message: 'Terima kasih atas masukannya, segera saya tindak lanjuti.',
                  time: '09:12',
                  avatarUrl: 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg',
                  unreadCount: 0,
                  isActive: false,
                ),
                _buildChatItem(
                  name: 'Arsitek Hendra',
                  message: 'Kapan kita bisa meeting untuk proyek Villa Ubud?',
                  time: 'Yesterday',
                  avatarUrl: 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar3.jpg',
                  unreadCount: 0,
                  isActive: false,
                ),
                _buildChatItem(
                  name: 'Grup Proyek Mall Jkt',
                  message: 'Irfan: Material baja sudah sampai di site.',
                  time: 'Mon',
                  avatarUrl: 'https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg',
                  unreadCount: 0,
                  isActive: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermintaanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERMINTAAN BARU', style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          if (permintaanList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Tidak ada permintaan saat ini.', style: TextStyle(color: Colors.black45)),
              ),
            ),
          ...permintaanList.map((item) => _buildPermintaanCard(item)).toList(),
          if (permintaanList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Semua permintaan ditampilkan', style: TextStyle(color: Colors.black45, fontSize: 10)),
                ),
                Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 24), // Extra space
          ],
        ],
      ),
    );
  }

  Widget _buildPermintaanCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(item['avatarUrl']),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50), // Dark blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item['role'], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Text(item['time'], style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 10, fontWeight: FontWeight.bold)), // Time color like design
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EBE3), // Light beige
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('"', style: TextStyle(color: Color(0xFF8F2A0C), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item['quote'],
                    style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      permintaanList.removeWhere((el) => el['id'] == item['id']);
                    });
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8F2A0C),
                    side: const BorderSide(color: Color(0xFF8F2A0C)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          chatId: item['id'],
                          receiverName: item['name'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.reply, size: 16, color: Colors.white),
                  label: const Text('Balas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F2A0C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String message,
    required String time,
    required String avatarUrl,
    required int unreadCount,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: name, receiverName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.transparent) : Border.all(color: Colors.transparent),
          boxShadow: isActive 
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] 
              : null,
        ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isActive)
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(avatarUrl),
                      backgroundColor: AppColors.cardCream,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  color: isActive ? AppColors.primary : Colors.black45,
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color: isActive ? Colors.black87 : Colors.black54,
                                    fontSize: 12,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
