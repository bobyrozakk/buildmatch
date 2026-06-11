// lib/modules/kontraktor/ui/screens/detail_proyek/detail_proyek_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/bid_model.dart';
import 'package:buildmatch/ui/shared/widgets/glass_card.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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

class DetailProyekScreen extends StatefulWidget {
  final ProjectModel project;
  const DetailProyekScreen(
      {super.key, required this.project});

  @override
  State<DetailProyekScreen> createState() =>
      _DetailProyekScreenState();
}

class _DetailProyekScreenState
    extends State<DetailProyekScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  bool _alreadyBid = false;
  bool _checkingBid = true;
  int _bidCount = 0;
  bool _specExpanded = false;
  BidModel? _myBid;

  // ── State untuk fitur baru ──
  int _estimationMonths = 3;
  File? _rabFile;
  String? _rabFileName;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final provider = context.read<ContractorProjectCubit>();
    final projectId = widget.project.id ?? '';
    final results = await Future.wait([
      provider.getVendorBidOnProject(projectId),
      provider.fetchProjectBidCount(projectId),
    ]);
    if (!mounted) return;
    
    final bid = results[0] as BidModel?;
    setState(() {
      _myBid = bid;
      _alreadyBid = bid != null;
      _bidCount = results[1] as int;
      _checkingBid = false;

      if (bid != null) {
        final digits = bid.price.toInt().toString();
        final buffer = StringBuffer();
        for (int i = 0; i < digits.length; i++) {
          if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
          buffer.write(digits[i]);
        }
        _priceController.text = buffer.toString();
        _messageController.text = bid.message ?? '';
        _estimationMonths = bid.estimationMonths ?? 3;
      }
    });
  }

  bool get _isCancelable {
    if (_myBid == null) return false;
    return _myBid!.status == 'pending' && 
           _myBid!.createdAt != null && 
           DateTime.now().difference(_myBid!.createdAt!).inHours < 24;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Pick file RAB ──
  Future<void> _pickRabFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _rabFile = File(result.files.single.path!);
        _rabFileName = result.files.single.name;
      });
    }
  }

  void _submitBid() async {
    if (_alreadyBid) return;

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Harga penawaran wajib diisi!')));
      return;
    }

    final provider = context.read<ContractorProjectCubit>();
    bool success = await provider.submitBid(
      projectId: widget.project.id ?? '',
      price: double.tryParse(_priceController.text.replaceAll('.', '')) ?? 0.0,
      message: _messageController.text.trim(),
      estimationMonths: _estimationMonths,
      rabFile: _rabFile,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _alreadyBid = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Penawaran Berhasil Dikirim',
        ),
      );
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengirim penawaran.'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelBid() async {
    final bidId = _myBid?.id;
    if (bidId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Text('Batalkan Penawaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan penawaran ini?\nAnda masih bisa mengajukan penawaran baru setelah dibatalkan.',
          style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade50,
              foregroundColor: Colors.orange.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _checkingBid = true;
    });

    final provider = context.read<ContractorProjectCubit>();
    final success = await provider.deleteBid(bidId: bidId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _myBid = null;
        _alreadyBid = false;
        _priceController.clear();
        _messageController.clear();
        _rabFile = null;
        _rabFileName = null;
        _checkingBid = false;
        if (_bidCount > 0) _bidCount--;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Penawaran Berhasil Dibatalkan',
        ),
      );
    } else {
      setState(() {
        _checkingBid = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membatalkan penawaran.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak dapat membuka tautan.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContractorProjectCubit, ContractorProjectState>(
      builder: (context, state) {
        final isLoading = state is ContractorProjectLoading;

        return Scaffold(
          backgroundColor: AppColors.backgroundCream,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Detail Proyek',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(
                  widget.project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              if (widget.project.status != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                      child: _buildStatusBadge(widget.project.status!)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Image ──
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
                                  child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 56,
                                      color: Colors.black26),
                                ),
                                loadingBuilder: (ctx, child, p) => p == null
                                    ? child
                                    : Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary)),
                                      ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_outlined,
                                    size: 56, color: Colors.black26),
                              ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3)
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildTitleCard(),
                const SizedBox(height: 16),
                _buildClientInfoCard(),
                const SizedBox(height: 20),
                _buildDescriptionCard(),
                const SizedBox(height: 20),
                _buildTechnicalSpecsCard(),

                // ── Lampiran & Lokasi ──
                if ((widget.project.referencePdfUrl != null &&
                        widget.project.referencePdfUrl!.isNotEmpty) ||
                    (widget.project.latitude != null &&
                        widget.project.longitude != null)) ...[
                  const SizedBox(height: 24),
                  Row(children: const [
                    Icon(Icons.attachment_rounded,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Lampiran Klien',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  if (widget.project.referencePdfUrl != null &&
                      widget.project.referencePdfUrl!.isNotEmpty)
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
                  if (widget.project.latitude != null &&
                      widget.project.longitude != null)
                    _attachmentTile(
                      icon: Icons.map_rounded,
                      iconColor: Colors.green.shade600,
                      title: 'Lokasi Proyek di Peta',
                      subtitle:
                          '${widget.project.latitude!.toStringAsFixed(5)}, ${widget.project.longitude!.toStringAsFixed(5)}',
                      actionLabel: 'Maps',
                      onTap: () => _openUrl(
                        'https://www.google.com/maps/search/?api=1&query=${widget.project.latitude},${widget.project.longitude}',
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                // ── Header Form Bid ──
                Row(children: const [
                  Icon(Icons.gavel_rounded,
                      size: 20, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Formulir Penawaran',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Text(
                    'Berikan penawaran terbaik untuk klien',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Form Bid Card ──
                IOSGlassCard(
                  blur: 15,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info budget client
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54),
                                    children: [
                                      const TextSpan(
                                          text: 'Budget klien: '),
                                      TextSpan(
                                        text: AppFormatters.formatRupiah(
                                            widget.project.budget),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const TextSpan(
                                          text:
                                              ' · Anda bisa menawar lebih rendah atau lebih tinggi'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input harga penawaran
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          enabled: !_alreadyBid,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandsSeparatorFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Harga Penawaran Anda',
                            prefixIcon: const Icon(
                                Icons.monetization_on_outlined,
                                color: AppColors.primary),
                            prefixText: 'Rp  ',
                            prefixStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Estimasi waktu pengerjaan
                        const Text(
                          'Estimasi Waktu Pengerjaan',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$_estimationMonths Bulan',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              _buildRoundCounter(
                                icon: Icons.remove,
                                onTap: !_alreadyBid &&
                                        _estimationMonths > 1
                                    ? () => setState(
                                        () => _estimationMonths--)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              _buildRoundCounter(
                                icon: Icons.add,
                                onTap: !_alreadyBid &&
                                        _estimationMonths < 60
                                    ? () => setState(
                                        () => _estimationMonths++)
                                    : null,
                                isActive: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Upload RAB
                        const Text(
                          'Upload RAB (Opsional)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rancangan Anggaran Biaya · PDF / Excel / Word · Maks. 5MB',
                          style: TextStyle(
                              fontSize: 11, color: Colors.black45),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _alreadyBid ? null : _pickRabFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 14),
                            decoration: BoxDecoration(
                              color: _rabFile != null
                                  ? AppColors.primary.withOpacity(0.06)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _rabFile != null
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _rabFile != null
                                      ? Icons.check_circle_rounded
                                      : Icons.upload_file_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _rabFileName ?? 'Pilih file RAB...',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _rabFile != null
                                          ? AppColors.primary
                                          : Colors.black45,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (_rabFile != null)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _rabFile = null;
                                      _rabFileName = null;
                                    }),
                                    child: const Icon(Icons.close,
                                        size: 18, color: Colors.black38),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pesan / catatan
                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          enabled: !_alreadyBid,
                          decoration: InputDecoration(
                            labelText: 'Pesan / Catatan ke Klien',
                            hintText:
                                'Contoh: Sudah termasuk material premium, garansi 1 tahun...',
                            hintStyle: const TextStyle(
                                color: Colors.black38, fontSize: 12),
                            prefixIcon: const Icon(
                                Icons.message_outlined,
                                color: AppColors.primary),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Tombol Submit ──
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
                    onPressed: isLoading || _checkingBid
                        ? null
                        : (_alreadyBid
                            ? (_isCancelable ? _cancelBid : null)
                            : _submitBid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _alreadyBid
                          ? (_isCancelable ? Colors.orange : Colors.grey.shade400)
                          : AppColors.primary,
                      disabledBackgroundColor: _alreadyBid
                          ? Colors.grey.shade400
                          : AppColors.primary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white),
                          )
                        : Icon(
                            _alreadyBid
                                ? (_isCancelable ? Icons.cancel_outlined : Icons.check_circle_rounded)
                                : Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _alreadyBid
                          ? (_isCancelable ? 'Batalkan Penawaran' : 'Sudah Menawar')
                          : (isLoading
                              ? 'Mengirim...'
                              : 'Kirim Penawaran ke Klien'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────

  Widget _buildRoundCounter({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.cardCream,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16,
            color: isActive ? Colors.white : AppColors.primary),
      ),
    );
  }

  Widget _specChip(
      IconData icon, String label, String value) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.8), width: 1),
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700)),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new_rounded,
                        size: 14, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status.toLowerCase()) {
      case 'open':
        bg = AppColors.primary;
        label = 'Baru';
        break;
      case 'in_progress':
        bg = Colors.orange.shade700;
        label = 'Berjalan';
        break;
      case 'completed':
        bg = Colors.green.shade700;
        label = 'Selesai';
        break;
      default:
        bg = Colors.grey.shade600;
        label = status;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.project.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.3)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  AppFormatters.formatRupiah(
                      widget.project.budget),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(Icons.location_on_outlined,
                  widget.project.location ?? '-'),
              _miniChip(Icons.calendar_today_rounded,
                  AppFormatters.timeAgo(widget.project.createdAt)),
              _miniChip(
                  Icons.gavel_outlined, '$_bidCount penawaran'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard() {
    final name = (widget.project.clientName?.isNotEmpty == true)
        ? widget.project.clientName!
        : 'Klien';
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(
                  'Pemilik proyek · $_bidCount penawaran masuk',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.timeAgo(widget.project.createdAt),
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.description_outlined,
                size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Deskripsi Proyek',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(
            widget.project.description?.isNotEmpty == true
                ? widget.project.description!
                : 'Tidak ada deskripsi rinci.',
            style: const TextStyle(
                color: Colors.black54, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _miniSpecTile('Luas Bangunan',
                      '${widget.project.buildingSize.toStringAsFixed(0)} m²')),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniSpecTile('Luas Tanah',
                      '${widget.project.landSize.toStringAsFixed(0)} m²')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _miniSpecTile(
                      'Gaya', widget.project.houseStyle)),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniSpecTile(
                      'Lantai', '${widget.project.floors}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniSpecTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _specExpanded = !_specExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.architecture_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Spesifikasi Teknis Lengkap',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                  Icon(
                    _specExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          if (_specExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                      child: _specChip(
                        Icons.account_balance_wallet_outlined,
                        'Anggaran',
                        AppFormatters.formatRupiah(widget.project.budget),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(
                        Icons.terrain_outlined,
                        'Luas Tanah',
                        '${widget.project.landSize.toStringAsFixed(0)} m²',
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(
                        Icons.home_outlined,
                        'Luas Bangunan',
                        '${widget.project.buildingSize.toStringAsFixed(0)} m²',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(Icons.layers_outlined,
                          'Lantai', '${widget.project.floors}'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(Icons.bed_outlined,
                          'Kamar Tidur', '${widget.project.bedrooms}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(Icons.bathtub_outlined,
                          'Kamar Mandi', '${widget.project.bathrooms}'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _specChip(Icons.style_outlined,
                          'Gaya', widget.project.houseStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _specChip(
                        Icons.location_on_outlined,
                        'Lokasi',
                        widget.project.location ?? '-',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}