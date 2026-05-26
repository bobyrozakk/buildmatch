import 'package:flutter/material.dart';
import '../../arsitek/widgets/buat_penawaran_sheet.dart';
import '../../arsitek/screens/kirim_desain_screen.dart';
import '../../arsitek/screens/detail_penawaran_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const ChatDetailScreen({super.key, required this.chatId, required this.receiverName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  // Lifecycle States:
  // 0: Pre-Offer (Belum Diajukan)
  // 1: Offer Sent (Menunggu Respons)
  // 2: Offer Accepted (Menunggu Pembayaran) -> **New State matching screenshot!**
  // 3: Payment Received (Pembayaran Selesai)
  int _offerState = 0; 
  bool _isSimulating = false;

  void _progressOfferState() {
    if (_isSimulating) return;
    
    setState(() => _isSimulating = true);

    if (_offerState == 1) {
      // Transition 1 -> 2: Offer Accepted / Waiting Payment
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Menyimulasikan penerimaan penawaran oleh klien...'),
            ],
          ),
          duration: Duration(milliseconds: 1200),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _offerState = 2;
            _isSimulating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Klien MENERIMA penawaran! Menunggu Pembayaran.'),
              backgroundColor: Color(0xFFFFC107),
            ),
          );
        }
      });
    } else if (_offerState == 2) {
      // Transition 2 -> 3: Payment Received / Selesai
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Menyimulasikan pembayaran dari klien...'),
            ],
          ),
          duration: Duration(milliseconds: 1200),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _offerState = 3;
            _isSimulating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran dikonfirmasi! Proyek berlanjut.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } else {
      setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiverNameText = _offerState >= 2 ? "Andi Wijaya" : widget.receiverName;
    final isDone = _offerState == 3;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg'),
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
                      border: Border.all(color: Colors.white, width: 2)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receiverNameText, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15)),
                Row(
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 4),
                    Text('Online', style: TextStyle(color: Colors.green, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF5C1C08), size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Top Warning Bar: Waiting Payment (Only in State 2!)
          if (_offerState == 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFFFFF3CD), // Light yellow warning color
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '⏳ ⌛ Waiting Payment',
                    style: TextStyle(
                      color: Color(0xFF856404),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.info, color: Color(0xFF856404), size: 14),
                ],
              ),
            ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: const Text('Hari ini', style: TextStyle(color: Colors.black54, fontSize: 11)),
                  ),
                ),
                
                // 1. Client Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3EBE3),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              _offerState >= 2 
                                  ? 'Halo Pak, apakah desain ini\nbisa dimodifikasi?'
                                  : 'Halo Pak, apakah desain ini\nTersedia?',
                              style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('10:30', style: TextStyle(color: Colors.black45, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40), // Margin right
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // 2. Architect Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 40), // Margin left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8F2A0C), // Dark brown
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              _offerState >= 2
                                  ? 'Siap, saya bisa bantu. Saya\nakan buatkan penawaran resmi ya!'
                                  : 'Tersedia. Saya akan\nbuatkan penawaran resmi ya!',
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('10:33', style: TextStyle(color: Colors.black45, fontSize: 10)),
                              SizedBox(width: 4),
                              Icon(Icons.done_all, size: 14, color: Color(0xFF8F2A0C)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 3. Architect Offer Card (visible if offer has been sent, state >= 1)
                if (_offerState >= 1) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailPenawaranScreen(isDone: isDone),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05), 
                                      blurRadius: 10, 
                                      offset: const Offset(0, 4)
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Card Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF8F2A0C),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16), 
                                          topRight: Radius.circular(16)
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.description, color: Colors.white, size: 16),
                                              SizedBox(width: 8),
                                              Text(
                                                'PENAWARAN RESMI', 
                                                style: TextStyle(
                                                  color: Colors.white, 
                                                  fontWeight: FontWeight.bold, 
                                                  fontSize: 11, 
                                                  letterSpacing: 0.5
                                                )
                                              ),
                                            ],
                                          ),
                                          if (_offerState >= 2)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00E676),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Text(
                                                    'DITERIMA', 
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8)
                                                  ),
                                                  SizedBox(width: 2),
                                                  Icon(Icons.check, color: Colors.white, size: 8),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Card Body
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Desain Rumah Minimalis 2 Lantai', 
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Layanan desain arsitektur lengkap termasuk denah, tampak, dan potongan...',
                                            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          Container(height: 1, color: Colors.grey.shade100),
                                          const SizedBox(height: 16),
                                          
                                          const Text('Harga Penawaran', style: TextStyle(color: Colors.black45, fontSize: 10)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _offerState >= 2 ? 'Rp 2.500.000' : 'Rp 670.000', 
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF8F2A0C))
                                          ),
                                          
                                          const SizedBox(height: 16),
                                          Container(height: 1, color: Colors.grey.shade100),
                                          const SizedBox(height: 16),
                                          
                                          if (_offerState < 2) ...[
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: const [
                                                Text('Pembayaran Terakhir', style: TextStyle(color: Colors.black45, fontSize: 10)),
                                                Text('22 Mei 2026', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54)),
                                              ],
                                            ),
                                          ] else ...[
                                            // Side-by-side cards from the new screenshot
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFDF5EE),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFF5E4D6)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: const [
                                                        Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF8F2A0C)),
                                                        SizedBox(width: 6),
                                                        Text('14 Hari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF8F2A0C))),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFDF5EE),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFF5E4D6)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: const [
                                                        Icon(Icons.refresh, size: 12, color: Color(0xFF8F2A0C)),
                                                        SizedBox(width: 6),
                                                        Text('2x Revisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF8F2A0C))),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.circle, 
                                                color: _offerState == 3 
                                                    ? Colors.green 
                                                    : (_offerState == 2 ? const Color(0xFF00E676) : const Color(0xFFFFC107)), 
                                                size: 8
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _offerState == 3 
                                                    ? 'Pembayaran Selesai' 
                                                    : (_offerState == 2 ? 'Penawaran Diterima ✓' : 'Menunggu Respons'), 
                                                style: TextStyle(
                                                  color: _offerState >= 2 ? Colors.green : Colors.black54, 
                                                  fontStyle: _offerState >= 2 ? FontStyle.normal : FontStyle.italic, 
                                                  fontWeight: _offerState >= 2 ? FontWeight.bold : FontWeight.normal,
                                                  fontSize: 11
                                                )
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('10:35', style: TextStyle(color: Colors.black45, fontSize: 10)),
                                SizedBox(width: 4),
                                Icon(Icons.done_all, size: 14, color: Color(0xFF8F2A0C)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // 4. Client Paid Reply (only visible if offerState == 3)
                if (_offerState == 3) ...[
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar2.jpg'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3EBE3),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Pembayaran sudah saya lakukan,\nmohon di cek',
                                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text('10:40', style: TextStyle(color: Colors.black45, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Margin right
                    ],
                  ),
                ],
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Bottom Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Row 1: Attachment Pills
                  Row(
                    children: [
                      Expanded(child: _buildAttachmentPill(Icons.attach_file, 'Lampiran')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAttachmentPill(Icons.image_outlined, 'Foto')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildAttachmentPill(Icons.description_outlined, 'File')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Row 2: Status Bar based on _offerState
                  if (_offerState == 0) ...[
                    // State 0: Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.assignment_outlined, size: 16, color: Colors.white),
                            label: const Text('Ajukan Penawaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8F2A0C),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => BuatPenawaranSheet(
                                  clientId: widget.chatId,
                                  onOfferSent: (bidId) {
                                    setState(() {
                                      _offerState = 1;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.send_outlined, size: 16, color: Color(0xFF8F2A0C)),
                            label: const Text('Kirim Desain', style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8F2A0C),
                              side: const BorderSide(color: Color(0xFF8F2A0C)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KirimDesainScreen(
                                    chatId: widget.chatId,
                                    receiverName: widget.receiverName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // State 1, 2, 3: Status Bars
                    GestureDetector(
                      onTap: _offerState < 3 ? _progressOfferState : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _offerState == 2 ? const Color(0xFFFFFDF5) : const Color(0xFFFCF8F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _offerState == 2 ? const Color(0xFFFFE0B2) : const Color(0xFFE5DCD3)
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _offerState == 2 ? Icons.hourglass_empty : Icons.history, 
                                  color: Colors.black54, 
                                  size: 16
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _offerState == 2 
                                          ? 'Menunggu Pembayaran' 
                                          : 'Penawaran Terkirim', 
                                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)
                                    ),
                                    if (_offerState < 3)
                                      Text(
                                        _offerState == 1 
                                            ? 'Tap badge untuk simulasikan penawaran diterima' 
                                            : 'Tap badge untuk simulasikan pembayaran selesai', 
                                        style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 9, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _offerState == 3 
                                    ? const Color(0xFFE2F0D9) 
                                    : (_offerState == 2 ? const Color(0xFFFFF3CD) : const Color(0xFFE5DCD3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle, 
                                    color: _offerState == 3 
                                        ? Colors.green 
                                        : (_offerState == 2 ? const Color(0xFFFFC107) : const Color(0xFFFFC107)), 
                                    size: 6
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _offerState == 3 
                                        ? 'Selesai' 
                                        : (_offerState == 2 ? 'Pending' : 'Menunggu'), 
                                    style: TextStyle(
                                      color: _offerState == 3 
                                          ? Colors.green 
                                          : (_offerState == 2 ? const Color(0xFF856404) : Colors.black54), 
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Row 3: Message Input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EBE3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.emoji_emotions_outlined, color: Colors.black54, size: 20),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Tulis pesan...',
                                    hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                              Icon(Icons.mic_none_outlined, color: Colors.black54, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8F2A0C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF8F2A0C), size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
