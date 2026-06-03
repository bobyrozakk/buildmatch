import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:buildmatch/data/providers/project_provider.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/data/models/review_model.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../shared/widgets/animated_success_dialog.dart';

/// Screen khusus CLIENT untuk melihat termin pembayaran, melakukan konfirmasi bayar,
/// dan meninjau laporan progres dari kontraktor.
///
/// Alur status termin:
/// pending → waiting_confirmation → confirmed → progress_submitted → completed
class ClientPaymentTermsScreen extends StatefulWidget {
  final String projectId;
  final double dealPrice;
  final String projectTitle;
  final String contractorName;
  final String contractorId;

  const ClientPaymentTermsScreen({
    super.key,
    required this.projectId,
    required this.dealPrice,
    required this.projectTitle,
    required this.contractorName,
    this.contractorId = '',
  });

  @override
  State<ClientPaymentTermsScreen> createState() =>
      _ClientPaymentTermsScreenState();
}

class _ClientPaymentTermsScreenState extends State<ClientPaymentTermsScreen> {
  late Future<List<PaymentTermModel>> _termsFuture;
  ProjectModel? _project;
  ReviewModel? _existingReview;
  bool _hasShownAlert = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prov = Provider.of<ProjectProvider>(context, listen: false);
    _termsFuture = prov.fetchPaymentTerms(widget.projectId);

    try {
      final p = await prov.fetchProjectById(widget.projectId);
      ReviewModel? r;
      if (p?.status == 'completed') {
        r = await prov.fetchProjectReview(widget.projectId);
        if (!_hasShownAlert) {
          _hasShownAlert = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showProjectCompletedAlert();
          });
        }
      }
      setState(() {
        _project = p;
        _existingReview = r;
      });
    } catch (e) {
      // Gagal mengambil data proyek
    }
  }

  void _refresh() => setState(() => _load());

  // ──────────────────────────────────────────────
  // BOTTOM SHEET: PILIH BANK & KONFIRMASI BAYAR
  // ──────────────────────────────────────────────
  Future<void> _showPaymentSheet(PaymentTermModel term) async {
    String? selectedBank;
    String? vaNumber;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Termin: ${term.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nominal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Jumlah yang harus dibayar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.formatRupiah(term.amount),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${term.percentage.toStringAsFixed(0)}% dari total harga',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pilih Bank Transfer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Grid bank
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      children: [
                        _BankTile(
                          bank: 'bca',
                          label: 'BCA',
                          color: const Color(0xFF0066AE),
                          isSelected: selectedBank == 'bca',
                          onTap: () => setSheet(() {
                            selectedBank = 'bca';
                            vaNumber = ProjectProvider.generateVirtualAccount(
                              'bca',
                            );
                          }),
                        ),
                        _BankTile(
                          bank: 'bni',
                          label: 'BNI',
                          color: const Color(0xFFFF6600),
                          isSelected: selectedBank == 'bni',
                          onTap: () => setSheet(() {
                            selectedBank = 'bni';
                            vaNumber = ProjectProvider.generateVirtualAccount(
                              'bni',
                            );
                          }),
                        ),
                        _BankTile(
                          bank: 'mandiri',
                          label: 'Mandiri',
                          color: const Color(0xFF003087),
                          isSelected: selectedBank == 'mandiri',
                          onTap: () => setSheet(() {
                            selectedBank = 'mandiri';
                            vaNumber = ProjectProvider.generateVirtualAccount(
                              'mandiri',
                            );
                          }),
                        ),
                        _BankTile(
                          bank: 'bri',
                          label: 'BRI',
                          color: const Color(0xFF00A650),
                          isSelected: selectedBank == 'bri',
                          onTap: () => setSheet(() {
                            selectedBank = 'bri';
                            vaNumber = ProjectProvider.generateVirtualAccount(
                              'bri',
                            );
                          }),
                        ),
                      ],
                    ),
                    // Nomor VA
                    if (selectedBank != null && vaNumber != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Nomor Virtual Account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.numbers_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vaNumber!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: vaNumber!),
                                );
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nomor VA disalin!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transfer tepat ${AppFormatters.formatRupiah(term.amount)} ke nomor VA di atas, lalu tekan tombol di bawah.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Tombol Sudah Membayar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: selectedBank == null
                            ? null
                            : () async {
                                final provider = Provider.of<ProjectProvider>(
                                  context,
                                  listen: false,
                                );
                                bool ok = false;
                                String errMsg = '';
                                try {
                                  ok = await provider.clientMarkAsPaid(
                                    termId: term.id!,
                                    paymentMethod: selectedBank!,
                                    virtualAccountNumber: vaNumber!,
                                  );
                                } catch (e) {
                                  errMsg = e.toString();
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? '✅ Pembayaran dikonfirmasi! Menunggu verifikasi kontraktor.'
                                            : '❌ Gagal: $errMsg',
                                      ),
                                      backgroundColor: ok
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                  if (ok) _refresh();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedBank != null
                              ? Colors.green
                              : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          color: selectedBank != null
                              ? Colors.white
                              : Colors.grey,
                          size: 20,
                        ),
                        label: Text(
                          selectedBank == null
                              ? 'Pilih bank terlebih dahulu'
                              : 'Saya Sudah Membayar',
                          style: TextStyle(
                            color: selectedBank != null
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // DIALOG: KONFIRMASI SETUJUI PROGRES
  // ──────────────────────────────────────────────
  Future<void> _confirmReviewProgress(PaymentTermModel term) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Setujui Laporan Progres?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan menyetujui laporan progres untuk "${term.name}". '
              'Kontraktor dapat melanjutkan ke tahap berikutnya.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.teal,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Setelah disetujui, termin ini berstatus Selesai dan tidak dapat diubah.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ya, Setujui',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    bool success = false;
    String errMsg = '';
    try {
      success = await provider.clientReviewProgress(term.id!);
    } catch (e) {
      errMsg = e.toString();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Laporan progres disetujui! Termin selesai.'
                : '❌ Gagal: $errMsg',
          ),
          backgroundColor: success ? Colors.teal : Colors.red,
        ),
      );
      if (success) _refresh();
    }
  }

  // ──────────────────────────────────────────────
  // BOTTOM SHEET: AJUKAN PERUBAHAN (REVISI)
  // ──────────────────────────────────────────────
  Future<void> _showRevisionSheet(PaymentTermModel term) async {
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: Colors.orange.shade700,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ajukan Perubahan',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  term.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kontraktor akan menerima catatan Anda dan perlu mengupload ulang laporan yang diperbaiki.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Input catatan
                      const Text(
                        'Catatan untuk Kontraktor *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Jelaskan apa yang perlu diperbaiki atau dilengkapi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Catatan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Tombol submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheet(() => isSubmitting = true);
                                  final provider = Provider.of<ProjectProvider>(
                                    context,
                                    listen: false,
                                  );
                                  bool ok = false;
                                  String errMsg = '';
                                  try {
                                    ok = await provider.clientRequestRevision(
                                      termId: term.id!,
                                      revisionNotes: notesCtrl.text.trim(),
                                    );
                                  } catch (e) {
                                    errMsg = e.toString();
                                  }
                                  setSheet(() => isSubmitting = false);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? '↩️ Perubahan diajukan. Kontraktor akan memperbaiki laporan.'
                                              : '❌ Gagal: $errMsg',
                                        ),
                                        backgroundColor: ok
                                            ? Colors.orange
                                            : Colors.red,
                                      ),
                                    );
                                    if (ok) _refresh();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          label: Text(
                            isSubmitting
                                ? 'Mengirim...'
                                : 'Kirim Catatan Revisi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // DIALOG: LIHAT GAMBAR PROGRES FULLSCREEN
  // ──────────────────────────────────────────────
  void _showImageViewer(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imageUrls.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: Image.network(
                  imageUrls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Termin Pembayaran',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.projectTitle,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: FutureBuilder<List<PaymentTermModel>>(
        future: _termsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final terms = snapshot.data ?? [];
          if (terms.isEmpty) return _buildEmptyState();

          // Hitung ringkasan — hanya termin yang payment-nya sudah diterima
          // Progress bar hanya naik jika termin sudah approved (completed)
          final completedAmount = terms
              .where((t) => t.isCompleted)
              .fold(0.0, (s, t) => s + t.amount);
          final totalAmount = terms.fold(0.0, (s, t) => s + t.amount);
          final paidCount = terms.where((t) => t.isPaymentReceived).length;
          final completedCount = terms.where((t) => t.isCompleted).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildRatingSection(terms),
              _buildContractorBanner(),
              const SizedBox(height: 16),
              _buildSummaryCard(
                terms,
                completedAmount,
                totalAmount,
                paidCount,
                completedCount,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tahapan Pembayaran (${terms.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...terms.map((t) => _buildClientTermCard(t)),
              const SizedBox(height: 16),
              // Catatan info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Setelah Anda klik "Sudah Membayar", kontraktor akan memverifikasi '
                        'dan mengirim laporan progres. Tinjau laporan untuk menyelesaikan termin.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────────
  Widget _buildContractorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              widget.contractorName.isNotEmpty
                  ? widget.contractorName[0].toUpperCase()
                  : 'K',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kontraktor',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
                Text(
                  widget.contractorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.handshake_rounded, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  'Deal',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    List<PaymentTermModel> terms,
    double totalPaid,
    double totalAmount,
    int paidCount,
    int completedCount,
  ) {
    final progress = totalAmount > 0 ? totalPaid / totalAmount : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Nilai Proyek',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatRupiah(widget.dealPrice),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _chip(
                Icons.check_circle_outline_rounded,
                '$paidCount/${terms.length} terbayar',
              ),
              const SizedBox(width: 8),
              _chip(Icons.task_alt_rounded, '$completedCount selesai'),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress Pembayaran',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTermCard(PaymentTermModel term) {
    // Warna & label status
    final Color statusColor;
    final String statusLabel;

    if (term.isCompleted) {
      statusColor = Colors.teal;
      statusLabel = 'Selesai ✓';
    } else if (term.isRevisionRequested) {
      statusColor = Colors.orange.shade700;
      statusLabel = 'Revisi Diminta ↩️';
    } else if (term.isProgressSubmitted) {
      statusColor = Colors.purple;
      statusLabel = 'Ada Laporan Baru!';
    } else if (term.isConfirmed) {
      statusColor = Colors.green;
      statusLabel = 'Terbayar';
    } else if (term.isWaitingConfirmation) {
      statusColor = Colors.orange;
      statusLabel = 'Menunggu Verifikasi';
    } else {
      statusColor = AppColors.primary;
      statusLabel = 'Belum Dibayar';
    }

    final Color? borderColor = term.isCompleted
        ? Colors.teal.shade200
        : term.isRevisionRequested
        ? Colors.orange.shade300
        : term.isProgressSubmitted
        ? Colors.purple.shade300
        : term.isConfirmed
        ? Colors.green.shade200
        : term.isWaitingConfirmation
        ? Colors.orange.shade300
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${term.orderIndex}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        term.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Nominal + persen
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardCream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Persentase',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${term.percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardCream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yang dibayar',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatRupiah(term.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Info pembayaran
                if (term.isWaitingConfirmation || term.isPaymentReceived) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: term.isPaymentReceived
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (term.paymentMethod != null)
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_rounded,
                                size: 14,
                                color: term.isPaymentReceived
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${term.paymentMethod!.toUpperCase()} Virtual Account',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: term.isPaymentReceived
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        if (term.virtualAccountNumber != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.numbers_rounded,
                                size: 14,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'VA: ${term.virtualAccountNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (term.isPaymentReceived &&
                            term.confirmedAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Dikonfirmasi kontraktor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // ── Laporan Progres dari Kontraktor ──
                if (term.isProgressSubmitted ||
                    term.isRevisionRequested ||
                    term.isCompleted) ...[
                  const SizedBox(height: 14),
                  _buildProgressSection(term),
                ],

                // Catatan
                if (term.notes != null && term.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          term.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action Buttons ──
          // Bayar sekarang (pending)
          if (term.isPending)
            _buildActionSection(
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentSheet(term),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.payment_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

          // Menunggu konfirmasi (info saja)
          if (term.isWaitingConfirmation)
            _buildActionSection(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Menunggu konfirmasi dari kontraktor...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Menunggu laporan progres (info)
          if (term.isConfirmed)
            _buildActionSection(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pembayaran diterima. Menunggu laporan progres...',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Dua tombol: Setujui + Ajukan Perubahan (progress_submitted)
          if (term.isProgressSubmitted)
            _buildActionSection(
              child: Row(
                children: [
                  // Tombol Ajukan Perubahan
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRevisionSheet(term),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.orange.shade400,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.orange.withValues(
                            alpha: 0.04,
                          ),
                        ),
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        label: Text(
                          'Ajukan Perubahan',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Setujui
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmReviewProgress(term),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.task_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Setujui',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Banner revisi (revision_requested) — client menunggu re-upload kontraktor
          if (term.isRevisionRequested)
            _buildActionSection(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Menunggu perbaikan dari kontraktor...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSection({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: child,
    );
  }

  // ──────────────────────────────────────────────
  // SECTION: LAPORAN PROGRES (CLIENT VIEW)
  // ──────────────────────────────────────────────
  Widget _buildProgressSection(PaymentTermModel term) {
    final isCompleted = term.isCompleted;
    final isRevision = term.isRevisionRequested;

    final bgColor = isCompleted
        ? Colors.teal.shade50
        : isRevision
        ? Colors.orange.shade50
        : Colors.purple.shade50;
    final borderColor = isCompleted
        ? Colors.teal.shade200
        : isRevision
        ? Colors.orange.shade300
        : Colors.purple.shade200;
    final accentColor = isCompleted
        ? Colors.teal
        : isRevision
        ? Colors.orange.shade700
        : Colors.purple;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header laporan
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.task_alt_rounded
                    : isRevision
                    ? Icons.edit_note_rounded
                    : Icons.assignment_turned_in_outlined,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'Laporan Progres — Disetujui'
                      : isRevision
                      ? 'Perubahan Diminta — Menunggu Revisi'
                      : 'Laporan Progres dari Kontraktor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          // Catatan revisi dari client (jika revision_requested)
          if (isRevision &&
              term.revisionNotes != null &&
              term.revisionNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Anda:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    term.revisionNotes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Deskripsi
          if (term.progressDescription != null &&
              term.progressDescription!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              term.progressDescription!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],

          // Thumbnail gambar (bisa diklik untuk fullscreen)
          if (term.progressImages != null &&
              term.progressImages!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${term.progressImages!.length} Foto Progres:',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: term.progressImages!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => _showImageViewer(term.progressImages!, i),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            term.progressImages![i],
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.black26,
                              ),
                            ),
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Icon zoom hint
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // PDF
          if (term.progressPdfUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: term.progressPdfUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔗 Link PDF disalin ke clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporan PDF Tersedia',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Ketuk untuk salin link PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Timestamp
          const SizedBox(height: 10),
          if (term.progressSubmittedAt != null)
            Text(
              'Dikirim: ${_formatDateTime(term.progressSubmittedAt!)}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          if (isRevision && term.revisionRequestedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Revisi diminta: ${_formatDateTime(term.revisionRequestedAt!)}',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
            ),
          ],
          if (isCompleted && term.progressReviewedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Disetujui: ${_formatDateTime(term.progressReviewedAt!)}',
              style: TextStyle(fontSize: 11, color: Colors.teal.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Termin Pembayaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kontraktor belum membuat tahapan pembayaran. Silakan hubungi kontraktor Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showProjectCompletedAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AnimatedSuccessDialog(
        message: 'Proyek Selesai! 🎉\nTerima kasih telah menggunakan jasa kami.',
      ),
    );
  }

  Widget _buildRatingSection(List<PaymentTermModel> terms) {
    if (_project?.status != 'completed') return const SizedBox.shrink();

    final vendorId = widget.contractorId.isNotEmpty
        ? widget.contractorId
        : terms.isNotEmpty
        ? terms.first.vendorId
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyek Selesai! 🎉',
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Terima kasih telah menggunakan jasa kami.',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          if (_existingReview != null) ...[
            const Text(
              'Ulasan Anda untuk Kontraktor:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < _existingReview!.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
            ),
            if (_existingReview!.comment != null &&
                _existingReview!.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${_existingReview!.comment}"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ] else ...[
            const Text(
              'Berikan Penilaian Anda:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (vendorId.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'Data kontraktor belum ditemukan, ulasan belum bisa dikirim.',
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
              )
            else
              _RatingInputWidget(
                onSubmitted: (rating, comment) async {
                  final ok =
                      await Provider.of<ProjectProvider>(
                        context,
                        listen: false,
                      ).addReview(
                        projectId: widget.projectId,
                        vendorId: vendorId,
                        rating: rating,
                        comment: comment,
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '✅ Ulasan berhasil dikirim!'
                              : '❌ Gagal mengirim ulasan',
                        ),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ),
                    );
                    if (ok) {
                      _load();
                    }
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _RatingInputWidget extends StatefulWidget {
  final Function(int rating, String comment) onSubmitted;

  const _RatingInputWidget({required this.onSubmitted});

  @override
  State<_RatingInputWidget> createState() => _RatingInputWidgetState();
}

class _RatingInputWidgetState extends State<_RatingInputWidget> {
  int _selectedRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starVal = index + 1;
            return IconButton(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() {
                        _selectedRating = starVal;
                      });
                    },
              icon: Icon(
                starVal <= _selectedRating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 36,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText: 'Tulis pesan ulasan Anda di sini...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.teal.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _submitting
                ? null
                : () async {
                    setState(() {
                      _submitting = true;
                    });
                    await widget.onSubmitted(
                      _selectedRating,
                      _commentCtrl.text,
                    );
                    if (mounted) {
                      setState(() {
                        _submitting = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Ulasan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// KOMPONEN TOMBOL BANK
// ──────────────────────────────────────────────
class _BankTile extends StatelessWidget {
  final String bank;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BankTile({
    required this.bank,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  label[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.black54,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
