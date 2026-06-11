// lib/modules/kontraktor/ui/widgets/progress_report_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_cubit.dart';
import 'package:buildmatch/modules/kontraktor/logic/contractor_project/contractor_project_state.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/core/constants/colors.dart';

extension _FileExtension on File {
  int get size => lengthSync();
}

class ProgressReportSheet extends StatefulWidget {
  final String projectId;
  final String termId;
  final ContractorProjectCubit cubit;
  final VoidCallback onSubmitted;

  const ProgressReportSheet({
    super.key,
    required this.projectId,
    required this.termId,
    required this.cubit,
    required this.onSubmitted,
  });

  @override
  State<ProgressReportSheet> createState() => _ProgressReportSheetState();
}

class _ProgressReportSheetState extends State<ProgressReportSheet> {
  final descCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final List<XFile> selectedImages = [];
  File? selectedPdf;
  String? pdfName;
  bool isSubmitting = false;
  String? uploadWarning;

  @override
  void dispose() {
    descCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    String termName = '';
    if (state is ContractorProjectLoaded) {
      final term = state.paymentTerms.firstWhere(
        (t) => t.id == widget.termId,
        orElse: () => PaymentTermModel(
          projectId: widget.projectId,
          bidId: '',
          vendorId: '',
          name: '',
          percentage: 0.0,
          amount: 0.0,
          orderIndex: 0,
        ),
      );
      termName = term.name;
    }

    Future<void> pickImages() async {
      if (selectedImages.length >= 5) {
        setState(() {
          uploadWarning = 'Maksimal 5 gambar';
        });
        return;
      }
      final picker = ImagePicker();
      final remaining = 5 - selectedImages.length;
      
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

      final List<XFile> valid = [];
      String? warning;
      for (final xf in picked) {
        final ext = xf.path.split('.').last.toLowerCase();
        final isSupported = ext == 'jpg' || ext == 'jpeg' || ext == 'png';
        final file = File(xf.path);
        
        if (!isSupported) {
          warning = 'Format file tidak didukung. Harap pilih foto JPG atau PNG.';
        } else if (file.size > 5 * 1024 * 1024) {
          warning = 'Ukuran foto ${xf.name} melebihi 5MB.';
        } else {
          valid.add(xf);
        }
      }

      setState(() {
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
        setState(() {
          selectedPdf = File(result.files.single.path!);
          pdfName = result.files.single.name;
        });
      }
    }

    Future<void> submitProgress() async {
      if (!formKey.currentState!.validate()) return;
      setState(() => isSubmitting = true);

      String errorMsg = '';
      bool ok = false;
      try {
        ok = await widget.cubit.submitTermProgress(
          termId: widget.termId,
          description: descCtrl.text.trim(),
          images: selectedImages.map((xf) => File(xf.path)).toList(),
          pdfFile: selectedPdf,
        );
      } catch (e) {
        errorMsg = e.toString();
      }

      if (mounted) {
        setState(() => isSubmitting = false);
      }
      if (ok) {
        if (mounted) {
          Navigator.pop(context);
        }
        widget.onSubmitted();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal: $errorMsg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          termName,
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const Text(
                        'Max 5 foto, masing-masing ≤ 5MB. Format: JPG, PNG.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                        ),
                      ),
                      if (uploadWarning != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uploadWarning!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(
                                    () => uploadWarning = null),
                                child: const Icon(Icons.close,
                                    color: Colors.red, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
                        child: selectedImages.isEmpty
                            ? _buildAddImageButton(pickImages)
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: selectedImages.length < 5
                                    ? selectedImages.length + 1
                                    : selectedImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
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
                                          cacheWidth: 200,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(
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
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedPdf != null)
                                GestureDetector(
                                  onTap: () => setState(() {
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
  }
}
