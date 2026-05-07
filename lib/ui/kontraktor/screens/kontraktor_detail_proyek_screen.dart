import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import '../../shared/widgets/glass_card.dart'; 

class KontraktorDetailProyekScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const KontraktorDetailProyekScreen({super.key, required this.project});

  @override
  State<KontraktorDetailProyekScreen> createState() => _KontraktorDetailProyekScreenState();
}

class _KontraktorDetailProyekScreenState extends State<KontraktorDetailProyekScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  void _submitBid() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga penawaran wajib diisi!')));
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    bool success = await provider.submitBid(
      projectId: widget.project['id'],
      price: double.tryParse(_priceController.text) ?? 0,
      message: _messageController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penawaran (Bid) berhasil dikirim!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim penawaran.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Detail & Penawaran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Proyek
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(widget.project['image_urls']?.isNotEmpty == true ? widget.project['image_urls'][0] : 'https://via.placeholder.com/400x200'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.project['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(widget.project['description'] ?? 'Tidak ada deskripsi rinci.', style: const TextStyle(color: Colors.black54, height: 1.5)),
            const SizedBox(height: 24),

            // Form Bid
            const Text('Formulir Penawaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            IOSGlassCard(
              blur: 15,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga Penawaran Anda (Rp)',
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF8B2B0F)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Pesan / Catatan ke Klien',
                        prefixIcon: const Icon(Icons.message_outlined, color: Color(0xFF8B2B0F)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2B0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Kirim Penawaran ke Klien', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}