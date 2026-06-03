import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/models/project_model.dart';
import 'package:latlong2/latlong.dart';
import '../../shared/screens/map_picker_screen.dart';
import '../../shared/widgets/animated_success_dialog.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

class CreateProjectScreen extends StatefulWidget {
  /// Jika [draft] diisi, form akan di-populate dengan data draft
  /// sehingga user bisa melanjutkan pengisian.
  final ProjectModel? draft;

  const CreateProjectScreen({super.key, this.draft});

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

  // ── ID draft yang sedang diedit (untuk dihapus otomatis setelah publish) ──
  String? _editingDraftId;

  // ── Spesifikasi bangunan ──
  int _bedrooms = 0;
  int _bathrooms = 0;
  int _floors = 1;
  String? _selectedStyle;

  // ── initState: populate form jika membuka dari draft ──
  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _editingDraftId = draft.id;
      _titleController.text = draft.title == 'Draft Tanpa Judul' ? '' : draft.title;
      _descController.text = draft.description ?? '';
      _buildingSizeController.text =
          draft.buildingSize > 0 ? draft.buildingSize.toStringAsFixed(0) : '';
      _locationController.text = draft.location ?? '';
      _bedrooms = draft.bedrooms;
      _bathrooms = draft.bathrooms;
      _floors = draft.floors;
      _selectedStyle = draft.houseStyle.isNotEmpty ? draft.houseStyle : null;
      if (draft.latitude != null && draft.longitude != null) {
        _selectedLocation = LatLng(draft.latitude!, draft.longitude!);
      }
      // Cari template tanah yang cocok berdasarkan size
      if (draft.landSize > 0) {
        try {
          _selectedLand = _landTemplates.firstWhere(
            (t) => (t['size'] as double) == draft.landSize,
          );
          _minBudget = _selectedLand!['basePrice'] as double;
        } catch (_) {
          // Template tidak ditemukan — biarkan null
        }
      }
      if (draft.budget > 0) _budget = draft.budget;
    }
  }

  final List<String> _houseStyles = [
    'Minimalis',
    'Modern',
    'Klasik',
    'Tropis',
    'Industrial',
  ];

  // ════════════════════════════════════════════════════
  // TEMPLATE TANAH — Referensi harga konstruksi Jatim 2025
  // basePrice = estimasi biaya konstruksi minimum (bukan harga beli tanah)
  // Biaya bangun standar Jatim 2025: ~Rp 4.000.000 – 6.000.000/m2
  // ════════════════════════════════════════════════════
  final List<Map<String, dynamic>> _landTemplates = [
    // Tipe 36 — Rumah starter
    // Luas tanah 60 m2 × biaya bangun ~Rp 4 jt/m2 = ~Rp 240 jt (dibulatkan)
    {
      'label': 'Tipe 36 (6 × 10 m)',
      'size': 60.0,
      'basePrice': 250_000_000.0,
    },

    // Tipe 45 — Perumahan menengah
    // Luas tanah 96 m2 × biaya bangun ~Rp 4,5 jt/m2 = ~Rp 430 jt
    {
      'label': 'Tipe 45 (8 × 12 m)',
      'size': 96.0,
      'basePrice': 450_000_000.0,
    },

    // Tipe 60 — Rumah keluarga
    // Luas tanah 150 m2 × biaya bangun ~Rp 5 jt/m2 = ~Rp 750 jt
    {
      'label': 'Tipe 60 (10 × 15 m)',
      'size': 150.0,
      'basePrice': 750_000_000.0,
    },

    // Tipe 72 — Perumahan premium
    // Luas tanah 144 m2 × biaya bangun ~Rp 5,5 jt/m2 = ~Rp 790 jt
    {
      'label': 'Tipe 72 (9 × 16 m)',
      'size': 144.0,
      'basePrice': 800_000_000.0,
    },

    // Tipe 90 — Rumah mewah
    // Luas tanah 180 m2 × biaya bangun ~Rp 6 jt/m2 = ~Rp 1,08 M
    {
      'label': 'Tipe 90 (10 × 18 m)',
      'size': 180.0,
      'basePrice': 1_100_000_000.0,
    },

    // Custom Mansion — Properti eksklusif
    // Luas tanah 375 m2 × biaya bangun ~Rp 6 jt/m2 = ~Rp 2,25 M (minimum)
    {
      'label': 'Custom Mansion (15 × 25 m)',
      'size': 375.0,
      'basePrice': 2_500_000_000.0,
    },
  ];

  Map<String, dynamic>? _selectedLand;
  double _budget = 0;
  double _minBudget = 0;
  double get _maxBudget {
    // Maksimum slider menyesuaikan template yang dipilih (3× basePrice)
    if (_selectedLand == null) return 2_000_000_000.0;
    final base = _selectedLand!['basePrice'] as double;
    // Minimal ceiling 2 M, maksimal 20 M untuk Mansion
    return (base * 3.0).clamp(2_000_000_000.0, 20_000_000_000.0);
  }

  // ── File fisik ──
  File? _selectedImageFile;
  File? _selectedPdfFile;
  final ImagePicker _picker = ImagePicker();

  // ════════════════════════════════════════════════════
  // COMPUTED GETTERS: batas dinamis berdasarkan pilihan
  // ════════════════════════════════════════════════════

  /// Batas lantai berdasarkan template tanah yang dipilih.
  int get _maxFloors {
    if (_selectedLand == null) return 5;
    return AppValidators.maxFloors(_selectedLand!['size'] as double);
  }

  /// Batas kamar tidur berdasarkan jumlah lantai (4 kamar/lantai).
  int get _maxBedrooms => AppValidators.maxBedroomsForFloors(_floors);

  /// Batas kamar mandi berdasarkan jumlah kamar tidur (kamar tidur + 1).
  int get _maxBathrooms => AppValidators.maxBathroomsForBedrooms(_bedrooms);

  // ════════════════════════════════════════════════════
  // HELPERS: clamp otomatis saat nilai berubah
  // ════════════════════════════════════════════════════

  void _clampRooms() {
    if (_bedrooms > _maxBedrooms) _bedrooms = _maxBedrooms;
    if (_bathrooms > _maxBathrooms) _bathrooms = _maxBathrooms;
  }

  void _onFloorsChanged(int newVal) {
    setState(() {
      _floors = newVal;
      _clampRooms();
    });
  }

  void _onBedroomsChanged(int newVal) {
    setState(() {
      _bedrooms = newVal;
      if (_bathrooms > _maxBathrooms) _bathrooms = _maxBathrooms;
    });
  }

  // ════════════════════════════════════════════════════
  // STEP VALIDATION
  // ════════════════════════════════════════════════════

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Judul proyek wajib diisi');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    final List<String> errors = AppValidators.validateBuildingSpecs(
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      buildingSize:
          double.tryParse(_buildingSizeController.text.trim()) ?? 0.0,
      landSizeM2: _selectedLand?['size'] as double?,
    );
    if (errors.isNotEmpty) {
      _showError(errors.first);
      return false;
    }
    if (_selectedStyle == null) {
      _showError('Pilih tipe rumah terlebih dahulu');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_selectedLand == null) {
      _showError('Pilih template luas tanah terlebih dahulu');
      return false;
    }
    if (_budget <= 0) {
      _showError('Tentukan budget proyek Anda');
      return false;
    }
    final int maxF = AppValidators.maxFloors(
      _selectedLand!['size'] as double,
    );
    if (_floors > maxF) {
      _showError(
        'Jumlah lantai ($_floors) melebihi batas untuk tanah ini '
        '(maks $maxF lantai). Kembali ke Step 2 untuk mengurangi.',
      );
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ════════════════════════════════════════════════════
  // DRAFT FUNCTIONS
  // ════════════════════════════════════════════════════

  /// Dipanggil saat user klik panah kiri (exit) di pojok kiri atas.
  /// Jika form masih kosong → langsung keluar.
  /// Jika ada isian → tampilkan dialog: Buang / Simpan Draft / Batal.
  Future<void> _onExitPressed() async {
    final bool hasContent = _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty ||
        _bedrooms > 0 ||
        _bathrooms > 0 ||
        _floors > 1 ||
        _selectedLand != null ||
        _selectedStyle != null;

    if (!hasContent) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Simpan sebagai Draft?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Progres pengisian yang sudah kamu buat bisa disimpan dan dilanjutkan nanti dari tab Progress.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text('Batal',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text('Buang',
                style: TextStyle(color: Colors.red.shade400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan Draft',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == 'discard') {
      Navigator.pop(context);
    } else if (result == 'save') {
      await _saveDraftAndExit();
    }
    // 'cancel' atau null → tetap di form
  }

  /// Simpan data form saat ini ke Supabase sebagai draft, lalu keluar.
  Future<void> _saveDraftAndExit() async {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    final success = await provider.saveDraft(
      draftId: _editingDraftId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      budget: _budget,
      landSize: (_selectedLand?['size'] as double?) ?? 0,
      buildingSize: double.tryParse(_buildingSizeController.text) ?? 0,
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      houseStyle: _selectedStyle ?? '',
      location: _locationController.text.trim(),
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('\u{1F4DD} Draft berhasil disimpan!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      _showError('Gagal menyimpan draft. Coba lagi.');
    }
  }

  // ════════════════════════════════════════════════════
  // NAVIGATION
  // ════════════════════════════════════════════════════

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;

    if (_currentStep == _totalSteps - 1) {
      _submitData();
      return;
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ════════════════════════════════════════════════════
  // TEMPLATE TANAH: auto-clamp saat dipilih
  // ════════════════════════════════════════════════════

  void _onTemplateSelected(Map<String, dynamic>? template) {
    if (template == null) return;
    final double landSize = template['size'] as double;
    final int maxF = AppValidators.maxFloors(landSize);
    final bool floorsAdjusted = _floors > maxF;

    setState(() {
      _selectedLand = template;
      _minBudget = template['basePrice'] as double;
      _budget = template['basePrice'] as double;
      if (_floors > maxF) _floors = maxF;
      _clampRooms();
    });

    if (floorsAdjusted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Jumlah lantai disesuaikan menjadi $maxF '
            'lantai untuk tanah ${landSize.toStringAsFixed(0)} m2',
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════
  // FILE PICKERS
  // ════════════════════════════════════════════════════

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() => _selectedImageFile = File(image.path));
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      double fileSizeInMB = file.lengthSync() / (1024 * 1024);
      if (fileSizeInMB > 2.0) {
        if (mounted) _showError('Ukuran PDF maksimal 2MB!');
        return;
      }
      setState(() => _selectedPdfFile = file);
    }
  }

  // ════════════════════════════════════════════════════
  // SUBMIT
  // ════════════════════════════════════════════════════

  void _submitData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLand == null ||
        _selectedStyle == null ||
        _selectedLocation == null) {
      _showError('Template Tanah, Desain, dan Peta Lokasi wajib diisi!');
      return;
    }

    final provider = Provider.of<ProjectProvider>(context, listen: false);
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
      // Hapus draft lama jika ini adalah lanjutan dari draft
      if (_editingDraftId != null) {
        await provider.deleteDraft(_editingDraftId!);
      }
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Proyek berhasil dipublikasikan! 🚀',
        ),
      );
      Navigator.pop(context);
    } else {
      _showError('Gagal membuat proyek. Coba lagi.');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _buildingSizeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProjectProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Panah kiri → exit dengan dialog draft
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    onPressed: isLoading ? null : _onExitPressed,
                  ),
                  const Text(
                    "Buat Proyek Baru",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Icon bookmark → simpan draft langsung
                  IconButton(
                    tooltip: 'Simpan sebagai draft',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    onPressed: isLoading ? null : _saveDraftAndExit,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildStepper(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(isLoading),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // STEP SCREENS
  // ════════════════════════════════════════════════════

  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Proyek",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Lengkapi detail dasar untuk memulai perencanaan proyek Anda.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 30),
          _buildSectionTitle("Judul Proyek"),
          _buildSmoothTextField(
            _titleController,
            "Contoh: Rumah 2 Lantai Minimalis",
            Icons.home_work_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Judul proyek wajib diisi' : null,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Deskripsi Proyek"),
          _buildSmoothTextField(
            _descController,
            "Ceritakan detail keinginan Anda...",
            Icons.description_outlined,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Spesifikasi Bangunan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Isi detail fisik bangunan yang akan Anda bangun.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _buildConstraintInfoCard(),
          const SizedBox(height: 20),
          _buildCounterCard(
            "Jumlah Lantai",
            Icons.layers_outlined,
            _floors,
            _onFloorsChanged,
            min: 1,
            max: _maxFloors,
            hint: _selectedLand != null
                ? 'Maks $_maxFloors lantai untuk tanah ini'
                : 'Pilih template tanah (Step 3) untuk batas lantai',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCounterCard(
                  "Kamar Tidur",
                  Icons.bed_outlined,
                  _bedrooms,
                  _onBedroomsChanged,
                  min: 0,
                  max: _maxBedrooms,
                  hint: 'Maks $_maxBedrooms (${_floors} lantai × 4)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCounterCard(
                  "Kamar Mandi",
                  Icons.bathtub_outlined,
                  _bathrooms,
                  (val) => setState(() => _bathrooms = val),
                  min: 0,
                  max: _maxBathrooms,
                  hint: 'Maks $_maxBathrooms (kamar tidur + 1)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Luas Bangunan"),
          _buildSmoothTextField(
            _buildingSizeController,
            "Contoh: 120",
            Icons.square_foot_rounded,
            isNumber: true,
            suffix: "m2",
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Tipe Rumah"),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _houseStyles.map((style) {
              final bool isSelected = _selectedStyle == style;
              return ChoiceChip(
                label: Text(
                  style,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF8B2B0F),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                onSelected: (selected) =>
                    setState(() => _selectedStyle = selected ? style : null),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Estimasi Budget",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tentukan ukuran tanah dan anggaran proyek Anda.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // ── Info referensi harga Jatim ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimasi biaya konstruksi minimum berdasarkan referensi harga Jawa Timur 2025 '
                    '(Rp 4–6 jt/m²). Belum termasuk harga beli tanah.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle("Template Luas Tanah"),
          _buildGlassDropdown<Map<String, dynamic>>(
            value: _selectedLand,
            hint: 'Pilih Template...',
            icon: Icons.landscape_outlined,
            items: _landTemplates
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t['label'],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _onTemplateSelected,
          ),

          if (_selectedLand != null) ...[
            const SizedBox(height: 12),
            _buildLandLimitInfo(),
          ],
          const SizedBox(height: 32),

          _buildSectionTitle("Budget Anda"),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _selectedLand != null ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      AppFormatters.formatRupiah(_budget),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6.0,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12.0,
                        elevation: 4,
                      ),
                    ),
                    child: Slider(
                      value: _budget < _minBudget ? _minBudget : _budget,
                      min: _minBudget > 0 ? _minBudget : 0,
                      max: _maxBudget,
                      divisions: 100,
                      onChanged: _selectedLand != null
                          ? (val) => setState(() => _budget = val)
                          : null,
                    ),
                  ),
                  if (_selectedLand != null)
                    Center(
                      child: Text(
                        'Minimal biaya konstruksi: ${AppFormatters.formatRupiah(_minBudget)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
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

  Widget _buildStep4() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lokasi & Inspirasi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Berikan gambaran lokasi dan referensi desain agar kontraktor lebih paham.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Lokasi Proyek"),
          _buildSmoothTextField(
            _locationController,
            "Pilih lokasi di peta...",
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),

          // ── Peta interaktif ──
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapPickerScreen(),
                ),
              );

              // MapPickerScreen sekarang bisa return LatLng atau Map{lat, lng, name}
              if (result != null) {
                LatLng pickedLocation;
                String? pickedName;

                if (result is LatLng) {
                  pickedLocation = result;
                } else if (result is Map) {
                  pickedLocation = LatLng(
                    result['lat'] as double,
                    result['lng'] as double,
                  );
                  pickedName = result['name'] as String?;
                } else {
                  return;
                }

                setState(() {
                  _selectedLocation = pickedLocation;
                  // Gunakan nama dari Nominatim jika tersedia, fallback ke koordinat
                  _locationController.text = pickedName?.isNotEmpty == true
                      ? pickedName!
                      : "Lat: ${pickedLocation.latitude.toStringAsFixed(4)}, "
                          "Lng: ${pickedLocation.longitude.toStringAsFixed(4)}";
                });
              }
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(
                    _selectedLocation != null
                        ? 'https://tile.openstreetmap.org/15/${((_selectedLocation!.longitude + 180) / 360 * 32768).floor()}/${((1 - (math.log(math.tan(_selectedLocation!.latitude * math.pi / 180) + 1 / math.cos(_selectedLocation!.latitude * math.pi / 180)) / math.pi)) / 2 * 32768).floor()}.png'
                        : 'https://tile.openstreetmap.org/13/6508/4055.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: _selectedLocation != null
                        ? Colors.green
                        : const Color(0xFF8B2B0F),
                    size: 40,
                  ),
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedLocation != null
                                ? Icons.check_circle
                                : Icons.map_outlined,
                            size: 16,
                            color: _selectedLocation != null
                                ? Colors.green
                                : const Color(0xFF8B2B0F),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLocation != null
                                ? "Titik Koordinat Disimpan!"
                                : "Ketuk untuk menentukan koordinat pasti",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle(
            "Foto Lokasi / Inspirasi (Terkompresi otomatis)",
          ),
          _buildUploadBox(
            title: _selectedImageFile == null
                ? "Unggah Foto (.jpg, .png)"
                : _selectedImageFile!.path.split('/').last,
            icon: Icons.add_photo_alternate_outlined,
            isUploaded: _selectedImageFile != null,
            onTap: _pickImage,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Dokumen Pendukung / Denah (Max 2MB)"),
          _buildUploadBox(
            title: _selectedPdfFile == null
                ? "Unggah PDF Referensi (.pdf)"
                : _selectedPdfFile!.path.split('/').last,
            icon: Icons.description_outlined,
            isUploaded: _selectedPdfFile != null,
            onTap: _pickPdf,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // REUSABLE UI COMPONENTS
  // ════════════════════════════════════════════════════

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final bool isActive = index <= _currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: index < _currentStep
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < _totalSteps - 1)
              Container(
                width: 40,
                height: 2,
                color: isActive ? AppColors.primary : Colors.grey.shade300,
              ),
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
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: isLoading ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "← Kembali",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading && _currentStep == _totalSteps - 1
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1
                          ? "Publikasikan ➔"
                          : "Lanjut ➔",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildConstraintInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B2B0F).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B2B0F).withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8B2B0F),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panduan Spesifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2B0F),
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoLine(
                  '${_floors} lantai → maks $_maxBedrooms kamar tidur '
                  '(${_floors} × 4)',
                ),
                _buildInfoLine(
                  '$_bedrooms kamar tidur → maks $_maxBathrooms kamar mandi',
                ),
                _buildInfoLine(
                  _selectedLand != null
                      ? 'Tanah ${(_selectedLand!['size'] as double).toStringAsFixed(0)} m2 → maks $_maxFloors lantai'
                      : 'Pilih template tanah (Step 3) untuk batas lantai',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '• $text',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  Widget _buildLandLimitInfo() {
    final double landSize = _selectedLand!['size'] as double;
    final int maxF = AppValidators.maxFloors(landSize);
    final bool isOk = _floors <= maxF;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOk ? Colors.green.shade200 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 16,
            color: isOk ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOk
                  ? 'Tanah ${landSize.toStringAsFixed(0)} m2: maks $maxF lantai — Anda memilih $_floors lantai ✓'
                  : 'Peringatan: $_floors lantai melebihi batas $maxF lantai untuk tanah ini',
              style: TextStyle(
                fontSize: 12,
                color: isOk ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmoothTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8B2B0F).withOpacity(0.7),
        ),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCounterCard(
    String title,
    IconData icon,
    int value,
    Function(int) onChanged, {
    int min = 0,
    int? max,
    String? hint,
  }) {
    final bool atMin = value <= min;
    final bool atMax = max != null && value >= max;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8B2B0F).withOpacity(0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoundBtn(
                Icons.remove,
                atMin ? null : () => onChanged(value - 1),
              ),
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildRoundBtn(
                Icons.add,
                atMax ? null : () => onChanged(value + 1),
                isRed: !atMax,
              ),
            ],
          ),
          if (atMax) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Batas Maksimum',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundBtn(
    IconData icon,
    VoidCallback? onTap, {
    bool isRed = false,
  }) {
    final bool isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade200
              : (isRed
                  ? const Color(0xFF8B2B0F)
                  : const Color(0xFFF7F4EF)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled
              ? Colors.grey.shade400
              : (isRed ? Colors.white : const Color(0xFF8B2B0F)),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8B2B0F).withOpacity(0.8),
        ),
        labelText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isUploaded
              ? const Color(0xFF8B2B0F).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUploaded ? const Color(0xFF8B2B0F) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: const Color(0xFF8B2B0F),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUploaded
                      ? const Color(0xFF8B2B0F)
                      : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}