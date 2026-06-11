// lib/modules/kontraktor/ui/screens/payment_terms/widgets/term_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buildmatch/data/models/payment_term_model.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';

class TermFormSheet extends StatefulWidget {
  final double dealPrice;
  final double usedPercent;
  final PaymentTermModel? editingTerm;
  final Function(String name, double percent, String dueDate) onSubmit;

  const TermFormSheet({
    super.key,
    required this.dealPrice,
    required this.usedPercent,
    this.editingTerm,
    required this.onSubmit,
  });

  @override
  State<TermFormSheet> createState() => _TermFormSheetState();
}

class _TermFormSheetState extends State<TermFormSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController pctCtrl;
  late final TextEditingController notesCtrl;
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.editingTerm?.name ?? '');
    pctCtrl = TextEditingController(
      text: widget.editingTerm?.percentage.toStringAsFixed(0) ?? '',
    );
    notesCtrl = TextEditingController(text: widget.editingTerm?.notes ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    pctCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (100.0 - widget.usedPercent).clamp(0.0, 100.0);
    final pct = double.tryParse(pctCtrl.text) ?? 0.0;
    final nominal = widget.dealPrice * pct / 100.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  widget.editingTerm == null
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
                    color: remaining <= 0.0 ? Colors.red : Colors.black45,
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
                  onChanged: (_) => setState(() {}),
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
                    final val = double.tryParse(v ?? '') ?? 0.0;
                    if (val <= 0.0) {
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
                    color: pct > 0.0
                        ? AppColors.primary.withOpacity(0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: pct > 0.0
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        color: pct > 0.0
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
                                color: pct > 0.0
                                    ? Colors.black54
                                    : Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pct > 0.0
                                  ? AppFormatters.formatRupiah(nominal)
                                  : '—',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: pct > 0.0
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
                            setState(() {
                              isSaving = true;
                            });
                            try {
                              await widget.onSubmit(
                                nameCtrl.text.trim(),
                                double.tryParse(pctCtrl.text) ?? 0.0,
                                notesCtrl.text.trim(),
                              );
                            } catch (e) {
                              debugPrint("Error saving term: $e");
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isSaving = false;
                                });
                              }
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
  }
}

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
