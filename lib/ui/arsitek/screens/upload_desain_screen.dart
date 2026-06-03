import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../core/constants/colors.dart';

class UploadDesainScreen extends StatefulWidget {
  const UploadDesainScreen({super.key});

  @override
  State<UploadDesainScreen> createState() => _UploadDesainScreenState();
}

class _UploadDesainScreenState extends State<UploadDesainScreen> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController(text: "120");
  final _costCtrl = TextEditingController(text: "500.000.000");
  final _descCtrl = TextEditingController();

  String _selectedStyle = "Modern Kontemporer";
  String _selectedType = "Rumah Tinggal";
  bool _showToPublic = true;
  bool _isLoading = false;

  final List<File> _imageFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDraft();
    });
  }

  Future<void> _checkForDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('portfolio_draft');
    if (draftStr != null && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFFCF8F5),
          title: const Text(
            'Lanjutkan Draft?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2A0C), fontSize: 16),
          ),
          content: const Text(
            'Apakah Anda ingin melanjutkan pengisian draft portofolio sebelumnya?',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                prefs.remove('portfolio_draft');
                Navigator.pop(ctx, false);
              },
              child: const Text('Hapus Draft', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan', style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        try {
          final data = jsonDecode(draftStr);
          setState(() {
            _nameCtrl.text = data['title'] ?? '';
            _selectedStyle = data['style'] ?? 'Modern Kontemporer';
            _selectedType = data['project_type'] ?? 'Rumah Tinggal';
            _areaCtrl.text = data['area'] ?? '120';
            _costCtrl.text = data['cost'] ?? '500.000.000';
            _descCtrl.text = data['description'] ?? '';
            _showToPublic = data['show_to_public'] ?? true;
            
            final List<dynamic> paths = data['image_paths'] ?? [];
            _imageFiles.clear();
            for (final p in paths) {
              final file = File(p.toString());
              if (file.existsSync()) {
                _imageFiles.add(file);
              }
            }
          });
        } catch (e) {
          debugPrint("Error loading draft: $e");
        }
      }
    }
  }

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
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _imageFiles.add(File(picked.path));
      });
    }
  }

  Future<void> _publishPortfolio() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Proyek wajib diisi!')),
      );
      return;
    }
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 foto proyek!')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
      imageFiles: _imageFiles,
      year: DateTime.now().year.toString(),
      isPublic: _showToPublic,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('portfolio_draft');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desain berhasil dipublikasikan ke portofolio publik!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mempublikasikan portofolio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftData = jsonEncode({
        'title': _nameCtrl.text,
        'style': _selectedStyle,
        'project_type': _selectedType,
        'area': _areaCtrl.text,
        'cost': _costCtrl.text,
        'description': _descCtrl.text,
        'show_to_public': _showToPublic,
        'image_paths': _imageFiles.map((f) => f.path).toList(),
      });
      await prefs.setString('portfolio_draft', draftData);
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft desain berhasil disimpan!'),
            backgroundColor: Color(0xFF8F2A0C),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving draft: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Desain', 
          style: TextStyle(color: Color(0xFF5C1C08), fontWeight: FontWeight.bold, fontSize: 16)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: OutlinedButton(
              onPressed: _saveDraft,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF8F2A0C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Simpan Draft', 
                style: TextStyle(color: Color(0xFF8F2A0C), fontWeight: FontWeight.bold, fontSize: 12)
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8F2A0C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload Main Card
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5DCD3)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDF5EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF8F2A0C), size: 24),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unggah Foto Proyek', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PNG, JPG hingga 10MB', 
                            style: TextStyle(color: Colors.black38, fontSize: 11)
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Previews Row
                  if (_imageFiles.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ..._imageFiles.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final file = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                image: DecorationImage(
                                  image: FileImage(file),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageFiles.removeAt(idx);
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(Icons.close, color: Colors.white, size: 10),
                                ),
                              ),
                            );
                          }),
                          
                          // Plus Button to add a thumbnail
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5DCD3)),
                              ),
                              child: const Icon(Icons.add, color: Colors.black45, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Nama Proyek
                  _buildLabel('Nama Proyek'),
                  _buildTextField(_nameCtrl, 'Contoh: Villa Sanur Minimalis'),
                  
                  const SizedBox(height: 16),
                  
                  // Gaya & Tipe Proyek side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Gaya'),
                            _buildDropdown(
                              _selectedStyle, 
                              ["Modern Kontemporer", "Minimalis", "Modern Tropis", "Industrial", "Skandinavia", "Brutalis"],
                              (val) => setState(() => _selectedStyle = val!)
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Tipe Proyek'),
                            _buildDropdown(
                              _selectedType,
                              ["Rumah Tinggal", "Kafe & Resto", "Kantor Modern", "Villa Resort", "Renovasi"],
                              (val) => setState(() => _selectedType = val!)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Luas & Biaya side-by-side
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Luas (m²)'),
                            _buildTextField(_areaCtrl, '120', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Biaya (Estimasi)'),
                            _buildTextField(
                              _costCtrl, 
                              '500.000.000', 
                              keyboardType: TextInputType.number,
                              prefixText: 'Rp'
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Deskripsi Proyek
                  _buildLabel('Deskripsi Proyek'),
                  _buildTextField(_descCtrl, 'Ceritakan konsep dan material unik yang Anda gunakan...', maxLines: 4),
                  
                  const SizedBox(height: 20),
                  
                  // Tampilkan ke Publik Card Button/Switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF5EE), // Soft pink/brown background
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF5E4D6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF5E4D6)),
                          ),
                          child: const Icon(Icons.public, color: Color(0xFF8F2A0C), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Tampilkan ke Publik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              SizedBox(height: 2),
                              Text('Izinkan klien melihat desain ini di portofolio Anda', style: TextStyle(color: Colors.black45, fontSize: 10, height: 1.3)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _showToPublic,
                          onChanged: (val) => setState(() => _showToPublic = val),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF8F2A0C),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Publikasikan ke Portofolio Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                      label: const Text('Publikasikan ke Portofolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: _publishPortfolio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA07A), // Or bright orange Color(0xFFE65100) or similar
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Helpers
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, {
    int maxLines = 1, 
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: prefixText != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Text(prefixText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 13)),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8F2A0C))),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
}
