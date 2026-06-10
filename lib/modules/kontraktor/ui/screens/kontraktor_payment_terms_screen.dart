import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────
// CATATAN DEPENDENCY (tambahkan ke pubspec.yaml jika belum ada):
//   image_picker: ^1.0.0
//   file_picker: ^6.0.0
// ─────────────────────────────────────────────────────────────────────────

/// Screen kontraktor untuk mengelola termin/tahap pembayaran sebuah proyek.
class KontraktorPaymentTermsScreen extends StatefulWidget {
  final String projectId;
  final String bidId;
  final double dealPrice;
  final String projectTitle;

  const KontraktorPaymentTermsScreen({
    super.key,
    required this.projectId,
    required this.bidId,
    required this.dealPrice,
    required this.projectTitle,
  });

  @override
  State<KontraktorPaymentTermsScreen> createState() =>
      _KontraktorPaymentTermsScreenState();
}

class _KontraktorPaymentTermsScreenState
    extends State<KontraktorPaymentTermsScreen> {
  late Future<List<PaymentTermModel>> _termsFuture;
  ProjectModel? _project;
  bool _loadingProject = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prov = context.read<ProjectCubit>();
    _termsFuture = prov.fetchPaymentTerms(widget.projectId);

    setState(() {
      _loadingProject = true;
    });
    try {
      final p = await prov.fetchProjectById(widget.projectId);
      setState(() {
        _project = p;
        _loadingProject = false;
      });
    } catch (e) {
      setState(() {
        _loadingProject = false;
      });
    }
  }

  void _refresh() => setState(() => _load());

  double _totalPercentage(List<PaymentTermModel> terms) =>
      terms.fold(0.0, (sum, t) => sum + t.percentage);

  // ──────────────────────────────────────────────
  // DIALOG TAMBAH / EDIT TERMIN
  // ──────────────────────────────────────────────
  Future<void> _showAddEditDialog({
    PaymentTermModel? existing,
    required int nextOrderIndex,
    required List<PaymentTermModel> allTerms,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pctCtrl = TextEditingController(
      text: existing?.percentage.toStringAsFixed(0) ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final usedByOthers = allTerms
                .where((t) => t.id != existing?.id)
                .fold(0.0, (s, t) => s + t.percentage);
            final remaining = (100.0 - usedByOthers).clamp(0.0, 100.0);
            final pct = double.tryParse(pctCtrl.text) ?? 0;
            final nominal = widget.dealPrice * pct / 100;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Form(
                    key: formKey,
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
                        Text(
                          existing == null
                              ? 'Tambah Termin Baru'
                              : 'Edit Termin',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sisa persentase tersedia: ${remaining.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: remaining <= 0 ? Colors.red : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Termin',
                            hintText: 'Contoh: DP Awal, Termin 1, Pelunasan',
                            prefixIcon: const Icon(
                              Icons.label_outline_rounded,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.cardCream,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama termin wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: pctCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                            _MaxPercentageFormatter(maxVal: remaining.toInt()),
                          ],
                          onChanged: (_) => setModal(() {}),
                          decoration: InputDecoration(
                            labelText: 'Persentase (%)',
                            hintText: 'Contoh: 30',
                            prefixIcon: const Icon(
                              Icons.percent_rounded,
                              color: AppColors.primary,
                            ),
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.cardCream,
                          ),
                          validator: (v) {
                            final val = double.tryParse(v ?? '');
                            if (val == null || val <= 0) {
                              return 'Masukkan persentase yang valid';
                            }
                            if (val > remaining) {
                              return 'Melebihi sisa persen (max ${remaining.toStringAsFixed(0)}%)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: pct > 0
                                ? AppColors.primary.withOpacity(0.06)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: pct > 0
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calculate_outlined,
                                color: pct > 0
                                    ? AppColors.primary
                                    : Colors.black26,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nominal yang harus dibayar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: pct > 0
                                            ? Colors.black54
                                            : Colors.black26,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      pct > 0
                                          ? AppFormatters.formatRupiah(nominal)
                                          : '—',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: pct > 0
                                            ? AppColors.primary
                                            : Colors.black26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Catatan (opsional)',
                            hintText:
                                'Misal: pembayaran untuk fondasi & struktur',
                            prefixIcon: const Icon(
                              Icons.notes_rounded,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.cardCream,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    final provider = context.read<ProjectCubit>();
                                    setModal(() {
                                      isSaving = true;
                                    });
                                    bool ok = false;
                                    String errorMsg = '';
                                    try {
                                      if (existing == null) {
                                        ok = await provider.addPaymentTerm(
                                          projectId: widget.projectId,
                                          bidId: widget.bidId,
                                          name: nameCtrl.text.trim(),
                                          percentage: double.parse(pctCtrl.text),
                                          dealPrice: widget.dealPrice,
                                          orderIndex: nextOrderIndex,
                                          notes: notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                        );
                                      } else {
                                        ok = await provider.editPaymentTerm(
                                          termId: existing.id!,
                                          name: nameCtrl.text.trim(),
                                          percentage: double.parse(pctCtrl.text),
                                          dealPrice: widget.dealPrice,
                                          notes: notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                        );
                                      }
                                    } catch (e) {
                                      errorMsg = e.toString();
                                    }
                                    if (!ok) {
                                      setModal(() {
                                        isSaving = false;
                                      });
                                    }
                                    if (ctx.mounted && ok) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? existing == null
                                                    ? '✅ Termin berhasil ditambahkan'
                                                    : '✅ Termin berhasil diperbarui'
                                                : '❌ Gagal menyimpan: $errorMsg',
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
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                            label: Text(
                              isSaving ? 'Menyimpan...' : 'Simpan Termin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
  // BOTTOM SHEET: KIRIM LAPORAN PROGRES (KONTRAKTOR)
  // ──────────────────────────────────────────────
  Future<void> _showProgressReportSheet(PaymentTermModel term) async {
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final List<XFile> selectedImages = [];
    File? selectedPdf;
    String? pdfName;
    bool isSubmitting = false;
    String? uploadWarning;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> pickImages() async {
              if (selectedImages.length >= 5) {
                setSheet(() {
                  uploadWarning = 'Maksimal 5 gambar';
                });
                return;
              }
              final picker = ImagePicker();
              final remaining = 5 - selectedImages.length;
              
              // Safe selection of remaining images: if 1, use pickImage; otherwise pickMultiImage
              final List<XFile> picked = [];
              try {
                if (remaining == 1) {
                  final single = await picker.pickImage(source: ImageSource.gallery);
                  if (single != null) picked.add(single);
                } else {
                  final multiple = await picker.pickMultiImage(limit: remaining);
                  if (multiple.isNotEmpty) picked.addAll(multiple);
                }
              } catch (_) {}
              
              if (picked.isEmpty) return;

              // Validasi ukuran dan format setiap gambar
              final List<XFile> valid = [];
              String? warning;
              for (final xf in picked) {
                final ext = xf.path.split('.').last.toLowerCase();
                final isSupported = ext == 'jpg' || ext == 'jpeg' || ext == 'png';
                final size = await File(xf.path).length();
                
                if (!isSupported) {
                  warning = 'Format file tidak didukung. Harap pilih foto JPG atau PNG.';
                } else if (size > 5 * 1024 * 1024) {
                  warning = 'Ukuran foto ${xf.name} melebihi 5MB.';
                } else {
                  valid.add(xf);
                }
              }

              setSheet(() {
                if (warning != null) {
                  uploadWarning = warning;
                } else {
                  uploadWarning = null;
                }
                final canAdd = 5 - selectedImages.length;
                selectedImages.addAll(valid.take(canAdd));
              });
            }

            Future<void> pickPdf() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (result != null && result.files.single.path != null) {
                setSheet(() {
                  selectedPdf = File(result.files.single.path!);
                  pdfName = result.files.single.name;
                });
              }
            }

            Future<void> submitProgress() async {
              if (!formKey.currentState!.validate()) return;
              setSheet(() => isSubmitting = true);

              final provider = ctx.read<ProjectCubit>();
              String errorMsg = '';
              bool ok = false;
              try {
                ok = await provider.submitTermProgress(
                  termId: term.id!,
                  description: descCtrl.text.trim(),
                  images: selectedImages.map((xf) => File(xf.path)).toList(),
                  pdfFile: selectedPdf,
                );
              } catch (e) {
                errorMsg = e.toString();
              }

              setSheet(() => isSubmitting = false);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? '✅ Laporan progres berhasil dikirim!'
                          : '❌ Gagal: $errorMsg',
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
                if (ok) _refresh();
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 4),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kirim Laporan Progres',
                                  style: TextStyle(
                                    fontSize: 16,
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
                    ),
                    const Divider(height: 24),
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Deskripsi ──
                              const Text(
                                'Catatan / Deskripsi Progres *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: descCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Deskripsikan pekerjaan yang sudah dilakukan pada termin ini...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardCream,
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Deskripsi wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              // ── Upload Gambar ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Foto Progres',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${selectedImages.length}/5',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selectedImages.length >= 5
                                          ? Colors.orange
                                          : Colors.black45,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Max 5 foto, masing-masing ≤ 5MB. Format: JPG, PNG.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                              if (uploadWarning != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          uploadWarning!,
                                          style: const TextStyle(color: Colors.red, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setSheet(() => uploadWarning = null),
                                        child: const Icon(Icons.close, color: Colors.red, size: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              // List gambar yang dipilih + tombol tambah
                              SizedBox(
                                height: 90,
                                child: selectedImages.isEmpty
                                    ? _buildAddImageButton(pickImages)
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: selectedImages.length < 5
                                            ? selectedImages.length + 1
                                            : selectedImages.length,
                                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (_, i) {
                                          if (i == selectedImages.length &&
                                              selectedImages.length < 5) {
                                            return SizedBox(
                                              width: 90,
                                              height: 90,
                                              child: _buildAddImageButton(
                                                pickImages,
                                              ),
                                            );
                                          }
                                          return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.file(
                                                  File(selectedImages[i].path),
                                                  fit: BoxFit.cover,
                                                  width: 90,
                                                  height: 90,
                                                  cacheWidth: 200, // Optimize memory for local thumbnails
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () => setSheet(
                                                    () => selectedImages
                                                        .removeAt(i),
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 20),

                              // ── Upload PDF ──
                              const Text(
                                'Laporan PDF (Opsional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: pickPdf,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: selectedPdf != null
                                        ? Colors.green.shade50
                                        : AppColors.cardCream,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selectedPdf != null
                                          ? Colors.green.shade300
                                          : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selectedPdf != null
                                            ? Icons.picture_as_pdf_rounded
                                            : Icons.upload_file_rounded,
                                        color: selectedPdf != null
                                            ? Colors.green
                                            : AppColors.primary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          pdfName ??
                                              'Ketuk untuk pilih file PDF',
                                          style: TextStyle(
                                            color: selectedPdf != null
                                                ? Colors.green.shade700
                                                : Colors.black54,
                                            fontSize: 13,
                                            fontWeight: selectedPdf != null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (selectedPdf != null)
                                        GestureDetector(
                                          onTap: () => setSheet(() {
                                            selectedPdf = null;
                                            pdfName = null;
                                          }),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.black38,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tombol Submit
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitProgress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: Text(
                            isSubmitting
                                ? 'Mengunggah...'
                                : 'Kirim Laporan Progres',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
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

  Widget _buildAddImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Tambah Foto',
              style: TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // KONFIRMASI PEMBAYARAN (KONTRAKTOR)
  // ──────────────────────────────────────────────
  Future<void> _confirmPayment(PaymentTermModel term) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Pembayaran?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfirmasi bahwa pembayaran untuk "${term.name}" '
              'telah Anda terima.',
            ),
            if (term.paymentMethod != null) ...[
              const SizedBox(height: 12),
              _infoRow(
                Icons.account_balance_rounded,
                'Bank',
                term.paymentMethod!.toUpperCase(),
              ),
              const SizedBox(height: 6),
              if (term.virtualAccountNumber != null)
                _infoRow(
                  Icons.numbers_rounded,
                  'No. VA',
                  term.virtualAccountNumber!,
                ),
            ],
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
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ya, Konfirmasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final provider = context.read<ProjectCubit>();
    bool success = false;
    String errMsg = '';
    try {
      success = await provider.vendorConfirmPayment(term.id!);
    } catch (e) {
      errMsg = e.toString();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Pembayaran dikonfirmasi! Silakan kirim laporan progres.'
                : '❌ Gagal mengkonfirmasi: $errMsg',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _refresh();
    }
  }

  // ──────────────────────────────────────────────
  // HAPUS TERMIN
  // ──────────────────────────────────────────────
  Future<void> _deleteTerm(PaymentTermModel term) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Termin?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Termin "${term.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final provider = context.read<ProjectCubit>();
    final success = await provider.deletePaymentTerm(term.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Termin dihapus' : '❌ Gagal menghapus'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _refresh();
    }
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
          final totalPct = _totalPercentage(terms);
          final remainingPct = (100.0 - totalPct).clamp(0.0, 100.0);
          final nextOrder = terms.length + 1;
          final isProgressFullyCompleted = terms.isNotEmpty &&
              terms.every((t) => t.isCompleted) &&
              totalPct >= 100.0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSummaryCard(totalPct, remainingPct, terms),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daftar Termin (${terms.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (terms.isEmpty)
                _buildEmptyTerms()
              else
                ...terms.map((t) => _buildTermCard(t, terms)),
              const SizedBox(height: 20),
              if (remainingPct > 0)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(
                      nextOrderIndex: nextOrder,
                      allTerms: terms,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      '+ Tambah Termin (sisa ${remainingPct.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '100% — Semua termin sudah terdefinisi',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_project?.status == 'in_progress') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: (isProgressFullyCompleted && !_loadingProject)
                        ? () => _confirmCompleteProject(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.done_all_rounded,
                      color: isProgressFullyCompleted ? Colors.white : Colors.black26,
                    ),
                    label: Text(
                      'Selesaikan Kontrak & Proyek',
                      style: TextStyle(
                        color: isProgressFullyCompleted ? Colors.white : Colors.black26,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              if (_project?.status == 'completed') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.teal,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proyek Telah Selesai',
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kontrak kerja telah berakhir dan proyek ini telah ditandai selesai.',
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────
  // SUMMARY CARD
  // ──────────────────────────────────────────────
  Widget _buildSummaryCard(
    double totalPct,
    double remainingPct,
    List<PaymentTermModel> terms,
  ) {
    // Termin "sudah dibayar" = confirmed, progress_submitted, atau completed
    final paidCount = terms.where((t) => t.isPaymentReceived).length;
    final completedCount = terms.where((t) => t.isCompleted).length;
    final completedPct = terms
        .where((t) => t.isCompleted)
        .fold(0.0, (s, t) => s + t.percentage);

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
            'Total Harga Deal',
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
              _summaryChip(
                Icons.pie_chart_outline_rounded,
                '${totalPct.toStringAsFixed(0)}% terdefinisi',
              ),
              const SizedBox(width: 8),
              _summaryChip(
                Icons.check_circle_outline_rounded,
                '$paidCount/${terms.length} terbayar',
              ),
              const SizedBox(width: 8),
              _summaryChip(
                Icons.task_alt_rounded,
                '$completedCount selesai',
              ),
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
                    'Progress Proyek (Disetujui Client)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    '${completedPct.toStringAsFixed(0)} / 100%',
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
                  value: completedPct / 100,
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

  Widget _summaryChip(IconData icon, String label) {
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // KARTU SATU TERMIN
  // ──────────────────────────────────────────────
  Widget _buildTermCard(
    PaymentTermModel term,
    List<PaymentTermModel> allTerms,
  ) {
    // Status visual
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    if (term.isCompleted) {
      statusColor = Colors.teal;
      statusLabel = 'Selesai ✓';
      statusIcon = Icons.verified_rounded;
    } else if (term.isRevisionRequested) {
      statusColor = Colors.deepOrange;
      statusLabel = 'Perlu Direvisi ⚠️';
      statusIcon = Icons.edit_note_rounded;
    } else if (term.isProgressSubmitted) {
      statusColor = Colors.purple;
      statusLabel = 'Menunggu Tinjauan';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (term.isConfirmed) {
      statusColor = Colors.green;
      statusLabel = 'Terbayar';
      statusIcon = Icons.check_circle_rounded;
    } else if (term.isWaitingConfirmation) {
      statusColor = Colors.orange;
      statusLabel = 'Tunggu Konfirmasi';
      statusIcon = Icons.access_time_rounded;
    } else {
      statusColor = Colors.blue.shade700;
      statusLabel = 'Belum Dibayar';
      statusIcon = Icons.radio_button_unchecked_rounded;
    }

    final Color? borderColor = term.isCompleted
        ? Colors.teal.shade200
        : term.isRevisionRequested
        ? Colors.deepOrange.shade200
        : term.isProgressSubmitted
        ? Colors.purple.shade200
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
                // Header: nama + status badge
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${term.orderIndex}',
                          style: const TextStyle(
                            color: AppColors.primary,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Persentase + Nominal
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        icon: Icons.percent_rounded,
                        label: 'Persentase',
                        value: '${term.percentage.toStringAsFixed(0)}%',
                        valueColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoTile(
                        icon: Icons.payments_outlined,
                        label: 'Nominal',
                        value: AppFormatters.formatRupiah(term.amount),
                        valueColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Info bank jika client sudah klik bayar
                if (term.isWaitingConfirmation || term.isPaymentReceived) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: term.isPaymentReceived
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: term.isPaymentReceived
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
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
                                'Dibayar via ${term.paymentMethod!.toUpperCase()}',
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
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (term.paidAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Diklaim: ${_formatDateTime(term.paidAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // ── Laporan Progres (jika sudah submit, revision, atau completed) ──
                if (term.isProgressSubmitted ||
                    term.isRevisionRequested ||
                    term.isCompleted) ...[
                  const SizedBox(height: 14),
                  _buildProgressReportSection(term),
                ],

                // ── Banner Revisi dari Client ──
                if (term.isRevisionRequested) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.deepOrange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.deepOrange.shade600, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Perbaikan Diminta oleh Client',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.deepOrange.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (term.revisionNotes != null &&
                            term.revisionNotes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.deepOrange.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Catatan dari client:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  term.revisionNotes!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (term.revisionRequestedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Diminta: ${_formatDateTime(term.revisionRequestedAt!)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.deepOrange.shade400),
                          ),
                        ],
                      ],
                    ),
                  ),
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

          // Action Buttons ──
          if (term.isPending ||
              term.isWaitingConfirmation ||
              term.isConfirmed ||
              term.isRevisionRequested)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                children: [
                  // Edit + Hapus saat pending
                  if (term.isPending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddEditDialog(
                          existing: term,
                          nextOrderIndex: term.orderIndex,
                          allTerms: allTerms,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteTerm(term),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        label: Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Konfirmasi pembayaran saat waiting
                  if (term.isWaitingConfirmation)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmPayment(term),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Konfirmasi Pembayaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                  // Kirim laporan progres saat confirmed
                  if (term.isConfirmed)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showProgressReportSheet(term),
                        icon: const Icon(
                          Icons.upload_file_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Kirim Laporan Progres',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                  // Upload ulang revisi
                  if (term.isRevisionRequested)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showProgressReportSheet(term),
                        icon: const Icon(
                          Icons.upload_file_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Upload Ulang Revisi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // WIDGET: TAMPILAN LAPORAN PROGRES
  // ──────────────────────────────────────────────
  Widget _buildProgressReportSection(PaymentTermModel term) {
    final isCompleted = term.isCompleted;
    final isRevision = term.isRevisionRequested;
    final bgColor = isCompleted
        ? Colors.teal.shade50
        : isRevision
            ? Colors.deepOrange.shade50
            : Colors.purple.shade50;
    final borderColor = isCompleted
        ? Colors.teal.shade200
        : isRevision
            ? Colors.deepOrange.shade200
            : Colors.purple.shade200;
    final labelColor = isCompleted
        ? Colors.teal
        : isRevision
            ? Colors.deepOrange
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
                        : Icons.hourglass_top_rounded,
                size: 16,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Text(
                isCompleted
                    ? 'Laporan Sudah Disetujui Client'
                    : isRevision
                        ? 'Laporan Perlu Direvisi'
                        : 'Laporan Progres Terkirim',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ],
          ),

          // Deskripsi
          if (term.progressDescription != null &&
              term.progressDescription!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              term.progressDescription!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],

          // Thumbnail gambar
          if (term.progressImages != null &&
              term.progressImages!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: term.progressImages!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => _showImageViewer(term.progressImages!, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        term.progressImages![i],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        cacheWidth: 200, // Optimize memory for network thumbnails
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black26,
                          ),
                        ),
                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          if (frame == null) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }
                          return child;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              '${term.progressImages!.length} foto',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],

          // PDF
          if (term.progressPdfUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final urlString = term.progressPdfUrl!;
                try {
                  final uri = Uri.parse(urlString);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    throw 'Could not launch';
                  }
                } catch (e) {
                  Clipboard.setData(ClipboardData(text: urlString));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal membuka PDF, link disalin ke clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 16,
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
                            'Ketuk untuk membuka file PDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Timestamp
          if (term.progressSubmittedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dikirim: ${_formatDateTime(term.progressSubmittedAt!)}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
          if (isCompleted && term.progressReviewedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Ditinjau: ${_formatDateTime(term.progressReviewedAt!)}',
              style: TextStyle(fontSize: 11, color: Colors.teal.shade600),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPER WIDGETS
  // ──────────────────────────────────────────────
  Widget _buildEmptyTerms() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Belum ada termin pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tambahkan tahapan pembayaran untuk proyek ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black87,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.black38),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmCompleteProject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Selesaikan Proyek?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menyelesaikan kontrak kerja dan menandai proyek ini sebagai SELESAI?\n\n'
          'Aksi ini akan mengakhiri hubungan kerja dan mengunci seluruh termin pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ya, Selesaikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _loadingProject = true;
      });
      final ok = await context.read<ProjectCubit>()
          .completeProject(widget.projectId);
      if (mounted) {
        setState(() {
          _loadingProject = false;
        });
        if (ok) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AnimatedSuccessDialog(
              message: 'Proyek berhasil diselesaikan! ✅',
            ),
          );
          _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal menyelesaikan proyek'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    if (frame == null) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      );
                    }
                    return child;
                  },
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
}

/// Custom TextInputFormatter yang membatasi input persentase ≤ maxVal dan ≤ 100
class _MaxPercentageFormatter extends TextInputFormatter {
  final int maxVal;
  const _MaxPercentageFormatter({required this.maxVal});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final parsed = int.tryParse(newValue.text);
    if (parsed == null) return oldValue;
    final effectiveMax = maxVal.clamp(0, 100);
    if (parsed > effectiveMax) {
      final clamped = effectiveMax.toString();
      return TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    return newValue;
  }
}
