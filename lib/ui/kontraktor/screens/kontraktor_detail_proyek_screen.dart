import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/data/models/project_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class KontraktorDetailProyekScreen extends StatefulWidget {
  final ProjectModel project;
  const KontraktorDetailProyekScreen({super.key, required this.project});

  @override
  State<KontraktorDetailProyekScreen> createState() => _KontraktorDetailProyekScreenState();
}

class _KontraktorDetailProyekScreenState extends State<KontraktorDetailProyekScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  bool _alreadyBid = false;
  bool _checkingBid = true;

  @override
  void initState() {
    super.initState();
    _checkExistingBid();
  }

  Future<void> _checkExistingBid() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    final result = await provider.hasVendorBidOnProject(widget.project.id ?? '');
    if (!mounted) return;
    setState(() {
      _alreadyBid = result;
      _checkingBid = false;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitBid() async {
    if (_alreadyBid) return;
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga penawaran wajib diisi!')));
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    bool success = await provider.submitBid(
      projectId: widget.project.id ?? '',
      price: double.tryParse(_priceController.text.replaceAll('.', '')) ?? 0,
      message: _messageController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      setState(() => _alreadyBid = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penawaran (Bid) berhasil dikirim!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim penawaran.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
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
            // Gambar Proyek (Hero)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.project.imageUrls.isNotEmpty
                        ? Image.network(
                            widget.project.imageUrls[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.black26),
                            ),
                            loadingBuilder: (ctx, child, p) => p == null
                                ? child
                                : Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                  ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_outlined, size: 56, color: Colors.black26),
                          ),
                    // Gradient overlay untuk kedalaman
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.project.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3),
            ),
            if (widget.project.clientName != null && widget.project.clientName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    'oleh ${widget.project.clientName}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              widget.project.description ?? 'Tidak ada deskripsi rinci.',
              style: const TextStyle(color: Colors.black54, height: 1.5, letterSpacing: 0.2),
            ),
            const SizedBox(height: 24),

            // Section: Spesifikasi Proyek
            Row(
              children: const [
                Icon(Icons.architecture_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Spesifikasi Proyek', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            IOSGlassCard(
              blur: 15,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _specChip(Icons.account_balance_wallet_outlined, 'Anggaran', AppFormatters.formatRupiah(widget.project.budget))),
                        const SizedBox(width: 12),
                        Expanded(child: _specChip(Icons.terrain_outlined, 'Luas Tanah', '${widget.project.landSize.toStringAsFixed(0)} m²')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _specChip(Icons.home_outlined, 'Luas Bangunan', '${widget.project.buildingSize.toStringAsFixed(0)} m²')),
                        const SizedBox(width: 12),
                        Expanded(child: _specChip(Icons.layers_outlined, 'Lantai', '${widget.project.floors}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _specChip(Icons.bed_outlined, 'Kamar Tidur', '${widget.project.bedrooms}')),
                        const SizedBox(width: 12),
                        Expanded(child: _specChip(Icons.bathtub_outlined, 'Kamar Mandi', '${widget.project.bathrooms}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _specChip(Icons.style_outlined, 'Gaya', widget.project.houseStyle)),
                        const SizedBox(width: 12),
                        Expanded(child: _specChip(Icons.location_on_outlined, 'Lokasi', widget.project.location ?? '-')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section: Lampiran & Lokasi (jika tersedia)
            if ((widget.project.referencePdfUrl != null && widget.project.referencePdfUrl!.isNotEmpty) ||
                (widget.project.latitude != null && widget.project.longitude != null)) ...[
              const SizedBox(height: 24),
              Row(
                children: const [
                  Icon(Icons.attachment_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Lampiran Klien', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.project.referencePdfUrl != null && widget.project.referencePdfUrl!.isNotEmpty)
                _attachmentTile(
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: Colors.red.shade600,
                  title: 'Dokumen Referensi',
                  subtitle: 'Denah / sketsa / brief dari klien',
                  actionLabel: 'Buka',
                  onTap: () => _openUrl(widget.project.referencePdfUrl!),
                ),
              if (widget.project.referencePdfUrl != null &&
                  widget.project.referencePdfUrl!.isNotEmpty &&
                  widget.project.latitude != null &&
                  widget.project.longitude != null)
                const SizedBox(height: 12),
              if (widget.project.latitude != null && widget.project.longitude != null)
                _attachmentTile(
                  icon: Icons.map_rounded,
                  iconColor: Colors.green.shade600,
                  title: 'Lokasi Proyek di Peta',
                  subtitle: '${widget.project.latitude!.toStringAsFixed(5)}, ${widget.project.longitude!.toStringAsFixed(5)}',
                  actionLabel: 'Maps',
                  onTap: () => _openUrl(
                    'https://www.google.com/maps/search/?api=1&query=${widget.project.latitude},${widget.project.longitude}',
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Form Bid
            Row(
              children: const [
                Icon(Icons.gavel_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Formulir Penawaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28),
              child: Text(
                'Berikan penawaran terbaik untuk klien',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
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
                      enabled: !_alreadyBid,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ThousandsSeparatorFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Harga Penawaran Anda',
                        prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                        prefixText: 'Rp  ',
                        prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      enabled: !_alreadyBid,
                      decoration: InputDecoration(
                        labelText: 'Pesan / Catatan ke Klien',
                        hintText: 'Contoh: Estimasi waktu 4 bulan, sudah termasuk material premium...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                        prefixIcon: const Icon(Icons.message_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _alreadyBid
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed: (isLoading || _alreadyBid || _checkingBid) ? null : _submitBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadyBid ? Colors.grey.shade400 : AppColors.primary,
                  disabledBackgroundColor: _alreadyBid
                      ? Colors.grey.shade400
                      : AppColors.primary.withOpacity(0.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        _alreadyBid ? Icons.check_circle_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  _alreadyBid
                      ? 'Anda Sudah Menawarkan'
                      : (isLoading ? 'Mengirim...' : 'Kirim Penawaran ke Klien'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _specChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return IOSGlassCard(
      blur: 15,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}