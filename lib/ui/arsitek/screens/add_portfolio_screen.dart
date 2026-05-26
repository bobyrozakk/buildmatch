import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';

class AddPortfolioScreen extends StatefulWidget {
  const AddPortfolioScreen({super.key});

  @override
  State<AddPortfolioScreen> createState() => _AddPortfolioScreenState();
}

class _AddPortfolioScreenState extends State<AddPortfolioScreen> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(text: "120");
  final _costCtrl = TextEditingController(text: "500.000.000");
  final _descCtrl = TextEditingController();

  String _selectedStyle = "Modern Kontemporer";
  String _selectedType = "Rumah Tinggal";
  bool _isPublic = true;
  
  final List<File> _images = [];

  final List<String> _styles = ["Modern Kontemporer", "Minimalis", "Tropis Modern", "Industrial", "Klasik"];
  final List<String> _types = ["Rumah Tinggal", "Villa Resort", "Kafe & Resto", "Kantor Modern"];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _costCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _images.add(File(picked.path));
      });
    }
  }

  Future<void> _submit(bool isDraft) async {
    if (_nameCtrl.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Proyek dan Minimal 1 foto wajib diisi!')));
      return;
    }

    final double cost = double.tryParse(_costCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    final double area = double.tryParse(_areaCtrl.text) ?? 0.0;

    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final success = await provider.addPortfolio(
      title: _nameCtrl.text.trim(),
      style: _selectedStyle,
      projectType: _selectedType,
      area: area,
      cost: cost,
      description: _descCtrl.text.trim(),
      imageFiles: _images,
      year: DateTime.now().year.toString(),
      isPublic: isDraft ? false : _isPublic,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDraft ? 'Portofolio disimpan sebagai draft.' : 'Portofolio berhasil dipublikasikan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan portofolio.'), backgroundColor: Colors.red));
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
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Upload Desain', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            child: OutlinedButton(
              onPressed: () => _submit(true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Simpan Draft', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadSection(),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Nama Proyek'),
                  _buildFigmaTextField(_nameCtrl, 'Contoh: Villa Sanur Minimalis'),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Gaya'),
                            _buildDropdown(_selectedStyle, _styles, (val) => setState(() => _selectedStyle = val!)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Tipe Proyek'),
                            _buildDropdown(_selectedType, _types, (val) => setState(() => _selectedType = val!)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Luas (m²)'),
                            _buildFigmaTextField(_areaCtrl, '120', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Biaya (Estimasi)'),
                            _buildEstimasiField(),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildLabel('Deskripsi Proyek'),
                  _buildFigmaTextField(_descCtrl, 'Ceritakan konsep dan material unik yang Anda gunakan...', maxLines: 4),

                  const SizedBox(height: 20),
                  _buildPublicToggle(),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                      label: const Text('Publikasikan ke Portofolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _submit(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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

  Widget _buildFigmaTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.black87)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEstimasiField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Rp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45)),
          ),
          Expanded(
            child: TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
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
                children: const [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 32),
                  SizedBox(height: 8),
                  Text('Unggah Foto Proyek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text('PNG, JPG hingga 10MB', style: TextStyle(color: Colors.black45, fontSize: 11)),
                ],
              ),
            ),
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, idx) {
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(image: FileImage(_images[idx]), fit: BoxFit.cover),
                          ),
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(idx)),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.cardCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.add, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublicToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.checklistBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.language_rounded, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tampilkan ke Publik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                SizedBox(height: 2),
                Text('Izinkan klien melihat desain ini di portofolio Anda', style: TextStyle(color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (val) => setState(() => _isPublic = val),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
