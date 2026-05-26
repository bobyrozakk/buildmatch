import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class KirimDesainScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const KirimDesainScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
  });

  @override
  State<KirimDesainScreen> createState() => _KirimDesainScreenState();
}

class _KirimDesainScreenState extends State<KirimDesainScreen> {
  final _notesCtrl = TextEditingController();
  bool _needsApproval = true;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Kirim Desain', style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF8F2A0C), size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              'Kirim draf desain terbaru Anda langsung ke klien untuk mendapatkan feedback atau persetujuan.',
              style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),

            _buildLabel('Pilih Klien / Proyek'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF8F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DCD3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Cari proyek aktif...', style: TextStyle(color: Colors.black45, fontSize: 13)),
                  Icon(Icons.keyboard_arrow_down, color: Colors.black45, size: 20),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            _buildLabel('Upload File Desain (Draf)'),
            
            CustomPaint(
              painter: DashedBorderPainter(color: const Color(0xFFD6C8BB), strokeWidth: 1.5, gap: 5),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA07A), // Light orange
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.upload_file, color: Color(0xFF8F2A0C), size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text('Klik atau seret file ke sini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 4),
                    const Text('Mendukung JPG, PNG, PDF (Maks. 50MB)', style: TextStyle(color: Colors.black54, fontSize: 11)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilePill('draf_fasad_v2.jpg', Icons.image),
                _buildFilePill('denah_layout_rev.pdf', Icons.picture_as_pdf),
              ],
            ),

            const SizedBox(height: 20),
            _buildLabel('Catatan untuk Klien'),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFCF8F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DCD3)),
              ),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Berikan penjelasan singkat mengenai revisi atau poin penting dalam desain ini...',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF8F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DCD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF8F2A0C), size: 24), // Shield icon
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Minta Persetujuan Formal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                        SizedBox(height: 2),
                        Text('Klien akan diminta menekan tombol setuju', style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.3)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _needsApproval,
                    onChanged: (val) => setState(() => _needsApproval = val),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF5C1C08), // Very dark brown
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF8F2A0C)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C), fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, size: 16, color: Colors.white),
                    label: const Text('Kirim ke Klien', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1C08), // Very dark brown
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8F2A0C),
        unselectedItemColor: Colors.black54,
        currentIndex: 1, // Desain is active
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.architecture), label: 'Desain'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 11)),
    );
  }

  Widget _buildFilePill(String filename, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF8F2A0C)),
          const SizedBox(width: 6),
          Text(filename, style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          const Icon(Icons.close, size: 12, color: Colors.black54),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double dashWidth = gap;
    final double dashSpace = gap;
    double startX = 0;
    
    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12));
    Path path = Path()..addRRect(rrect);
    
    Path dashPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
