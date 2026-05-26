import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';

class UploadDesignScreen extends StatefulWidget {
  const UploadDesignScreen({super.key});

  @override
  State<UploadDesignScreen> createState() => _UploadDesignScreenState();
}

class _UploadDesignScreenState extends State<UploadDesignScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: "67.000.000");

  String _selectedBuildingType = "Villa Residensial";
  String _selectedStyle = "Tropis Modern";
  
  final List<File> _selectedImages = [];

  final List<String> _buildingTypes = ["Villa Residensial", "Rumah Tinggal", "Ruko Komersial", "Kafe & Resto"];
  final List<String> _styles = ["Tropis Modern", "Minimalis", "Industrial", "Klasik Kontemporer", "Brutalis"];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _selectedImages.add(File(picked.path));
      });
    }
  }

  Future<void> _submit(bool isDraft) async {
    if (_nameCtrl.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Minimal 1 foto wajib diisi!')));
      return;
    }

    final double price = double.tryParse(_priceCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;

    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final success = await provider.addPortfolio(
      title: _nameCtrl.text.trim(),
      style: _selectedStyle,
      projectType: _selectedBuildingType,
      area: 150, // default area placeholder
      cost: price,
      description: _descCtrl.text.trim(),
      imageFiles: _selectedImages,
      year: DateTime.now().year.toString(),
      isPublic: !isDraft,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Desain disimpan sebagai draft.' : 'Desain berhasil dipublikasikan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan desain.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ArchitectProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Upload Design Project', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Design Project'),
                  _buildFigmaTextField(_nameCtrl, 'Masukkan nama untuk desain Project'),
                  
                  const SizedBox(height: 16),
                  _buildLabel('Deskripsi'),
                  _buildFigmaTextField(_descCtrl, 'Deskripsi desain Project...', maxLines: 4),

                  const SizedBox(height: 16),
                  _buildLabel('Tipe Bangunan'),
                  _buildDropdown(_selectedBuildingType, _buildingTypes, (val) => setState(() => _selectedBuildingType = val!)),

                  const SizedBox(height: 16),
                  _buildLabel('Gaya'),
                  _buildDropdown(_selectedStyle, _styles, (val) => setState(() => _selectedStyle = val!)),

                  const SizedBox(height: 24),
                  _buildLabel('Foto Design Project'),
                  _buildUploadContainer(),

                  const SizedBox(height: 24),
                  _buildLabel('Harga Penawaran (Rp)'),
                  _buildPriceField(),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.crop_free_rounded, size: 18),
                            label: const Text('Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _submit(true),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            label: const Text('Publikasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            onPressed: () => _submit(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildFigmaTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardCreamLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUploadContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.checklistBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary, size: 28),
                  const SizedBox(height: 8),
                  const Text('Tambah Desain Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 4),
                  const Text('Tap untuk memilih file', style: TextStyle(color: Colors.black45, fontSize: 11)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.cardCream, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.photo_library_outlined, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Galeri', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(image: FileImage(_selectedImages[idx]), fit: BoxFit.cover),
                    ),
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImages.removeAt(idx)),
                      child: const CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 10,
                        child: Icon(Icons.close, color: Colors.white, size: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardCreamLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            ),
          ),
          const Icon(Icons.edit_rounded, color: Colors.black54, size: 18),
        ],
      ),
    );
  }
}
