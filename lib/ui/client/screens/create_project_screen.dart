import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/project_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/screens/map_picker_screen.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _buildingSizeController = TextEditingController();
  final _locationController = TextEditingController();
  LatLng? _selectedLocation;

  int _bedrooms = 0;
  int _bathrooms = 0;
  int _floors = 1;
  String? _selectedStyle;
  final List<String> _houseStyles = ['Minimalis', 'Modern', 'Klasik', 'Tropis', 'Industrial'];

  final List<Map<String, dynamic>> _landTemplates = [
    {'label': 'Tipe 36 (6 x 10 m)', 'size': 60.0, 'basePrice': 250000000.0},
    {'label': 'Tipe 45 (8 x 12 m)', 'size': 96.0, 'basePrice': 350000000.0},
    {'label': 'Tipe 60 (10 x 15 m)', 'size': 150.0, 'basePrice': 550000000.0},
    {'label': 'Custom Mansion (12 x 20 m)', 'size': 240.0, 'basePrice': 900000000.0},
  ];
  Map<String, dynamic>? _selectedLand;
  double _budget = 0;
  double _minBudget = 0;
  final double _maxBudget = 2000000000.0; 

  // --- STATE UNTUK FILE FISIK ---
  File? _selectedImageFile;
  File? _selectedPdfFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _buildingSizeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(Map<String, dynamic>? template) {
    if (template != null) {
      setState(() {
        _selectedLand = template;
        _minBudget = template['basePrice'];
        _budget = template['basePrice']; 
      });
    }
  }

  // --- FUNGSI AMBIL FOTO (DENGAN NATIVE COMPRESSION) ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _selectedImageFile = File(image.path));
    }
  }

  // --- FUNGSI AMBIL PDF (DENGAN LIMIT 2MB) ---
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      int fileSizeInBytes = file.lengthSync();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 2.0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ukuran PDF maksimal 2MB!'), backgroundColor: Colors.redAccent));
        return;
      }
      setState(() => _selectedPdfFile = file);
    }
  }

  void _submitData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLand == null || _selectedStyle == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template Tanah, Desain, dan Peta Lokasi wajib diisi!'), backgroundColor: Colors.redAccent));
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    // Kirim data ke Provider (DUPLIKAT UDAH GUE HAPUS)
    bool success = await provider.createProject(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      budget: _budget,
      landSize: _selectedLand!['size'],
      buildingSize: double.tryParse(_buildingSizeController.text) ?? 0.0,
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      houseStyle: _selectedStyle!,
      location: _locationController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      imageFile: _selectedImageFile, 
      pdfFile: _selectedPdfFile,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Proyek berhasil dipublikasikan! 🚀'), backgroundColor: Colors.green.shade800));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat proyek. Coba lagi.'), backgroundColor: Colors.redAccent));
    }
  }

  void _nextStep() {
    if (_currentStep == _totalSteps - 1) {
      _submitData();
      return;
    }
    setState(() => _currentStep++);
    _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream, 
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20)), onPressed: isLoading ? null : _prevStep),
                  const Text("Buat Proyek Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 20)), onPressed: () {}),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: _buildStepper()),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), 
                  children: [ _buildStep1(), _buildStep2(), _buildStep3(), _buildStep4() ],
                ),
              ),
            ),
            _buildBottomNav(isLoading),
          ],
        ),
      ),
    );
  }

  // --- KOMPONEN UI ---
  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        bool isActive = index <= _currentStep;
        return Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.white, shape: BoxShape.circle, border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade300, width: 2)),
              child: Center(child: index < _currentStep ? const Icon(Icons.check, color: Colors.white, size: 18) : Text("${index + 1}", style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade400, fontWeight: FontWeight.bold))),
            ),
            if (index < _totalSteps - 1) Container(width: 40, height: 2, color: isActive ? AppColors.primary : Colors.grey.shade300),
          ],
        );
      }),
    );
  }

  Widget _buildBottomNav(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFFF7F4EF)),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(flex: 1, child: OutlinedButton(onPressed: isLoading ? null : _prevStep, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.white, side: const BorderSide(color: Colors.transparent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("← Kembali", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: isLoading && _currentStep == _totalSteps - 1 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Text(_currentStep == _totalSteps - 1 ? "Publikasikan ➔" : "Lanjut ➔", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Informasi Proyek", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Lengkapi detail dasar untuk memulai perencanaan proyek Anda.", style: TextStyle(color: Colors.black54)), const SizedBox(height: 30),
          _buildSectionTitle("Judul Proyek"), _buildSmoothTextField(_titleController, "Contoh: Rumah 2 Lantai Minimalis", Icons.home_work_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul proyek wajib diisi' : null), const SizedBox(height: 24),
          _buildSectionTitle("Deskripsi Proyek"), _buildSmoothTextField(_descController, "Ceritakan detail keinginan Anda...", Icons.description_outlined, maxLines: 4),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Spesifikasi Bangunan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Isi detail fisik bangunan yang akan Anda bangun.", style: TextStyle(color: Colors.black54)), const SizedBox(height: 24),
          Row(children: [Expanded(child: _buildCounterCard("Kamar Tidur", Icons.bed_outlined, _bedrooms, (val) => setState(() => _bedrooms = val))), const SizedBox(width: 16), Expanded(child: _buildCounterCard("Kamar Mandi", Icons.bathtub_outlined, _bathrooms, (val) => setState(() => _bathrooms = val)))]), const SizedBox(height: 16),
          _buildCounterCard("Jumlah Lantai", Icons.layers_outlined, _floors, (val) => setState(() => _floors = val), min: 1), const SizedBox(height: 24),
          _buildSectionTitle("Luas Bangunan"), _buildSmoothTextField(_buildingSizeController, "Contoh: 120", Icons.square_foot_rounded, isNumber: true, suffix: "m²"), const SizedBox(height: 24),
          _buildSectionTitle("Tipe Rumah"),
          Wrap(spacing: 10, runSpacing: 10, children: _houseStyles.map((style) { bool isSelected = _selectedStyle == style; return ChoiceChip(label: Text(style, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)), selected: isSelected, selectedColor: const Color(0xFF8B2B0F), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)), onSelected: (selected) => setState(() => _selectedStyle = selected ? style : null)); }).toList()),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Estimasi Budget", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Tentukan ukuran tanah dan anggaran proyek Anda.", style: TextStyle(color: Colors.black54)), const SizedBox(height: 24),
          _buildSectionTitle("Template Luas Tanah"), _buildGlassDropdown<Map<String, dynamic>>(value: _selectedLand, hint: 'Pilih Template...', icon: Icons.landscape_outlined, items: _landTemplates.map((t) => DropdownMenuItem(value: t, child: Text(t['label']))).toList(), onChanged: _onTemplateSelected), const SizedBox(height: 32),
          _buildSectionTitle("Budget Anda"),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300), opacity: _selectedLand != null ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text(AppFormatters.formatRupiah(_budget), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary))), const SizedBox(height: 16),
                  SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 6.0, activeTrackColor: AppColors.primary, inactiveTrackColor: Colors.grey.shade200, thumbColor: Colors.white, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0, elevation: 4)), child: Slider(value: _budget < _minBudget ? _minBudget : _budget, min: _minBudget > 0 ? _minBudget : 0, max: _maxBudget, divisions: 100, onChanged: _selectedLand != null ? (val) => setState(() => _budget = val) : null)),
                  if (_selectedLand != null) Center(child: Text('Minimal harga pasaran: ${AppFormatters.formatRupiah(_minBudget)}', style: const TextStyle(fontSize: 12, color: Colors.black38, fontStyle: FontStyle.italic)))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Lokasi & Inspirasi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
          const Text("Berikan gambaran lokasi dan referensi desain agar kontraktor lebih paham.", style: TextStyle(color: Colors.black54)), const SizedBox(height: 24),
          _buildSectionTitle("Lokasi Proyek"), _buildSmoothTextField(_locationController, "Pilih lokasi di peta...", Icons.location_on_outlined), const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () async {
              // Buka layar peta, dan tunggu user milih titik
              final LatLng? pickedLocation = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPickerScreen()),
              );

              // Kalau user berhasil milih (gak asal back)
              if (pickedLocation != null) {
                setState(() {
                  _selectedLocation = pickedLocation;
                  // (Opsional) Auto-isi textfield lokasi dengan kordinat kalau masih kosong
                  if (_locationController.text.isEmpty) {
                    _locationController.text = "Lat: ${pickedLocation.latitude.toStringAsFixed(4)}, Lng: ${pickedLocation.longitude.toStringAsFixed(4)}";
                  }
                });
              }
            },
            child: Container(
              height: 150, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, 
                borderRadius: BorderRadius.circular(16), 
                // Kalau udah milih lokasi, tampilkan peta statis area tersebut. Kalau belum, pake gambar dummy
                image: DecorationImage(
                  image: NetworkImage(
                      _selectedLocation != null 
                        ? 'https://tile.openstreetmap.org/15/${((_selectedLocation!.longitude + 180) / 360 * 32768).floor()}/${((1 - (math.log(math.tan(_selectedLocation!.latitude * math.pi / 180) + 1 / math.cos(_selectedLocation!.latitude * math.pi / 180)) / math.pi)) / 2 * 32768).floor()}.png' 
                        : 'https://tile.openstreetmap.org/13/6508/4055.png'
                      ), 
                    fit: BoxFit.cover
                  )
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.location_on, color: _selectedLocation != null ? Colors.green : const Color(0xFF8B2B0F), size: 40),
                  Positioned(
                    bottom: 12, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(20)), 
                      child: Row(
                        children: [
                          Icon(_selectedLocation != null ? Icons.check_circle : Icons.map_outlined, size: 16, color: _selectedLocation != null ? Colors.green : const Color(0xFF8B2B0F)), 
                          const SizedBox(width: 8), 
                          Text(_selectedLocation != null ? "Titik Koordinat Disimpan!" : "Ketuk untuk menentukan koordinat pasti", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))
                        ]
                      )
                    )
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionTitle("Foto Lokasi / Inspirasi (Terkompresi otomatis)"),
          _buildUploadBox(
            title: _selectedImageFile == null ? "Unggah Foto (.jpg, .png)" : _selectedImageFile!.path.split('/').last,
            icon: Icons.add_photo_alternate_outlined,
            isUploaded: _selectedImageFile != null,
            onTap: _pickImage,
          ),
          const SizedBox(height: 16),

          _buildSectionTitle("Dokumen Pendukung / Denah (Max 2MB)"),
          _buildUploadBox(
            title: _selectedPdfFile == null ? "Unggah PDF Referensi (.pdf)" : _selectedPdfFile!.path.split('/').last,
            icon: Icons.description_outlined,
            isUploaded: _selectedPdfFile != null,
            onTap: _pickPdf,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- REUSABLE UI COMPONENTS ---
  Widget _buildSectionTitle(String title) { return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87))); }
  
  Widget _buildSmoothTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, bool isNumber = false, String? suffix, String? Function(String?)? validator}) {
    return TextFormField(controller: controller, maxLines: maxLines, keyboardType: isNumber ? TextInputType.number : TextInputType.text, validator: validator, decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.black38, fontSize: 14), prefixIcon: Icon(icon, color: const Color(0xFF8B2B0F).withOpacity(0.7)), suffixText: suffix, suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: Colors.white));
  }

  Widget _buildCounterCard(String title, IconData icon, int value, Function(int) onChanged, {int min = 0}) {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: const Color(0xFF8B2B0F).withOpacity(0.7), size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54))]), const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildRoundBtn(Icons.remove, () => value > min ? onChanged(value - 1) : null), Text("$value", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), _buildRoundBtn(Icons.add, () => onChanged(value + 1), isRed: true)])
        ],
      ),
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onTap, {bool isRed = false}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isRed ? const Color(0xFF8B2B0F) : const Color(0xFFF7F4EF), shape: BoxShape.circle), child: Icon(icon, size: 16, color: isRed ? Colors.white : const Color(0xFF8B2B0F))));
  }

  Widget _buildGlassDropdown<T>({required T? value, required String hint, required IconData icon, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(value: value, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54), decoration: InputDecoration(prefixIcon: Icon(icon, color: const Color(0xFF8B2B0F).withOpacity(0.8)), labelText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)), items: items, onChanged: onChanged);
  }

  Widget _buildUploadBox({required String title, required IconData icon, required bool isUploaded, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(color: isUploaded ? const Color(0xFF8B2B0F).withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUploaded ? const Color(0xFF8B2B0F) : Colors.transparent, style: BorderStyle.solid, width: 1.5)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUploaded ? Icons.check_circle_rounded : icon, color: const Color(0xFF8B2B0F)), const SizedBox(width: 8),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: isUploaded ? const Color(0xFF8B2B0F) : Colors.black54))),
          ],
        ),
      ),
    );
  }
}