
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buildmatch/modules/client/logic/project/project_cubit.dart';
import 'package:buildmatch/modules/client/logic/project/project_state.dart';
import 'package:buildmatch/data/models/project_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:buildmatch/ui/shared/screens/map_picker_screen.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/core/utils/formatters.dart';
import 'package:buildmatch/core/utils/validators.dart';
import 'widgets/create_project_house_style_card.dart';
import 'widgets/create_project_constraint_info.dart';
import 'widgets/create_project_counter_card.dart';

class CreateProjectScreen extends StatefulWidget {
  /// Jika [draft] diisi, form akan di-populate dengan data draft
  /// sehingga user bisa melanjutkan pengisian.
  final ProjectModel? draft;

  /// Jika true, form akan melakukan UPDATE proyek yang sudah ada (status='open')
  /// bukan membuat proyek baru atau menyimpan sebagai draft.
  final bool isEditMode;

  const CreateProjectScreen({super.key, this.draft, this.isEditMode = false});

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

  // Controllers untuk input custom luas tanah (panjang × lebar)
  final _customLandPanjangController = TextEditingController();
  final _customLandLebarController = TextEditingController();

  LatLng? _selectedLocation;

  // ── ID draft yang sedang diedit (untuk dihapus otomatis setelah publish) ──
  String? _editingDraftId;

  // ── Spesifikasi bangunan ──
  int _bedrooms = 0;
  int _bathrooms = 0;
  int _floors = 1;
  String? _selectedStyle;

  // Harga borongan standar Jatim 2025: Rp 4.000.000 / m²
  static const double _hargaBoronganPerM2 = 4_000_000.0;

  // ── State untuk file di server (draft) ──
  String? _serverImageUrl;
  String? _serverPdfUrl;
  bool _isDrafting = false;
  bool _isConsulting = false;

  // ── initState: populate form jika membuka dari draft ──
  @override
  void initState() {
    super.initState();
    _customLandPanjangController.addListener(_onCustomLandChanged);
    _customLandLebarController.addListener(_onCustomLandChanged);
    _buildingSizeController.addListener(_onBuildingSizeChanged);
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
      
      // Restore files
      _serverImageUrl = draft.imageUrls.isNotEmpty ? draft.imageUrls.first : null;
      _serverPdfUrl = draft.referencePdfUrl;

      // ── Restore pilihan luas tanah ──
      if (draft.landSize > 0) {
        // Cek apakah ada dimensi custom yang tersimpan
        if (draft.landCustomPanjang != null && draft.landCustomLebar != null) {
          // Restore sebagai custom
          _selectedLand = _customTemplate;
          // Set controller setelah frame pertama agar listener tidak terpicu prematur
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _customLandPanjangController.text =
                draft.landCustomPanjang!.toStringAsFixed(
                  draft.landCustomPanjang! % 1 == 0 ? 0 : 2,
                );
            _customLandLebarController.text =
                draft.landCustomLebar!.toStringAsFixed(
                  draft.landCustomLebar! % 1 == 0 ? 0 : 2,
                );
            // Hitung ulang budget minimum
            final ls = draft.landCustomPanjang! * draft.landCustomLebar!;
            setState(() {
              _minBudget = ls * 0.6 * _hargaBoronganPerM2;
              if (draft.budget > 0) _budget = draft.budget;
            });
          });
        } else {
          // Coba cocokkan dengan template standar
          try {
            _selectedLand = _landTemplates.firstWhere(
              (t) => (t['size'] as double) == draft.landSize,
            );
            _minBudget = _selectedLand!['basePrice'] as double;
          } catch (_) {
            // Template tidak ditemukan — biarkan null
          }
        }
      }

      // Restore budget (harus setelah _minBudget di-set)
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
  // TEMPLATE TANAH — harga minimum = luas_tanah × 60% × Rp 4.000.000
  // ════════════════════════════════════════════════════

  // Sentinel untuk pilihan Custom
  static const Map<String, dynamic> _customTemplate = {
    'label': 'Custom (Masukkan sendiri)',
    'size': 0.0,
    'basePrice': 0.0,
    'isCustom': true,
  };

  final List<Map<String, dynamic>> _landTemplates = [
    // Tipe 36 — 6×10 m = 60 m² → 60×0.6×Rp4jt = Rp 144 jt
    {'label': 'Tipe 36 (6 × 10 m)', 'size': 60.0, 'basePrice': 144_000_000.0},
    // Tipe 45 — 8×12 m = 96 m² → 96×0.6×Rp4jt = Rp 230,4 jt
    {'label': 'Tipe 45 (8 × 12 m)', 'size': 96.0, 'basePrice': 230_400_000.0},
    // Tipe 60 — 10×15 m = 150 m² → 150×0.6×Rp4jt = Rp 360 jt
    {'label': 'Tipe 60 (10 × 15 m)', 'size': 150.0, 'basePrice': 360_000_000.0},
    // Tipe 72 — 9×16 m = 144 m² → 144×0.6×Rp4jt = Rp 345,6 jt
    {'label': 'Tipe 72 (9 × 16 m)', 'size': 144.0, 'basePrice': 345_600_000.0},
    // Tipe 90 — 10×18 m = 180 m² → 180×0.6×Rp4jt = Rp 432 jt
    {'label': 'Tipe 90 (10 × 18 m)', 'size': 180.0, 'basePrice': 432_000_000.0},
    // Mansion — 15×25 m = 375 m² → 375×0.6×Rp4jt = Rp 900 jt
    {'label': 'Mansion (15 × 25 m)', 'size': 375.0, 'basePrice': 900_000_000.0},
  ];

  Map<String, dynamic>? _selectedLand;
  double _budget = 0;
  double _minBudget = 0;

  /// True jika user memilih opsi Custom
  bool get _isCustomLand =>
      _selectedLand != null && (_selectedLand!['isCustom'] == true);

  /// Luas tanah dari input custom (panjang × lebar)
  double get _customLandSize {
    final p = double.tryParse(_customLandPanjangController.text) ?? 0.0;
    final l = double.tryParse(_customLandLebarController.text) ?? 0.0;
    return p * l;
  }

  /// Luas tanah efektif (custom atau dari template)
  double get _effectiveLandSize {
    if (_isCustomLand) return _customLandSize;
    return (_selectedLand?['size'] as double?) ?? 0.0;
  }

  /// Budget minimum otomatis: luas tanah × 60% × Rp 4.000.000
  double get _autoMinBudget {
    final ls = _effectiveLandSize;
    if (ls <= 0) return 0.0;
    return ls * 0.6 * _hargaBoronganPerM2;
  }

  /// Dipanggil saat input custom berubah untuk update budget realtime
  void _onCustomLandChanged() {
    if (!_isCustomLand) return;

    // Batasi input panjang secara otomatis
    final pStr = _customLandPanjangController.text;
    final pVal = double.tryParse(pStr) ?? 0.0;
    if (pVal > 200.0) {
      _customLandPanjangController.value = TextEditingValue(
        text: '200',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    // Batasi input lebar secara otomatis
    final lStr = _customLandLebarController.text;
    final lVal = double.tryParse(lStr) ?? 0.0;
    if (lVal > 200.0) {
      _customLandLebarController.value = TextEditingValue(
        text: '200',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    final newMin = _autoMinBudget;
    final ls = _customLandSize;
    final int maxF = ls > 0 ? AppValidators.maxFloors(ls) : 5;

    // Hitung max budget baru berdasarkan newMin
    double newMax = 20_000_000_000.0;
    if (newMin > 0) {
      newMax = (newMin * 5.0).clamp(2_000_000_000.0, 20_000_000_000.0);
    }

    setState(() {
      _minBudget = newMin;
      if (_budget < newMin) {
        _budget = newMin;
      } else if (_budget > newMax) {
        _budget = newMax;
      }
      if (_floors > maxF) {
        _floors = maxF;
        _clampRooms();
      }
    });
  }

  /// Dipanggil saat luas bangunan diinput untuk membatasi nilai maksimal
  void _onBuildingSizeChanged() {
    final valStr = _buildingSizeController.text;
    final val = double.tryParse(valStr) ?? 0.0;
    if (val > 20000.0) {
      _buildingSizeController.value = TextEditingValue(
        text: '20000',
        selection: const TextSelection.collapsed(offset: 5),
      );
    }
    setState(() {});
  }

  /// Batas max luas bangunan: min(90% dari luas tanah, 20.000 m²)
  double get _maxBuildingSize {
    final ls = _effectiveLandSize;
    if (ls <= 0) return 20000.0;
    return math.min(ls * 0.9, 20000.0);
  }

  double get _maxBudget {
    final minB = _isCustomLand ? _autoMinBudget : (_minBudget > 0 ? _minBudget : 0);
    if (minB <= 0) return 20_000_000_000.0;
    return (minB * 5.0).clamp(2_000_000_000.0, 20_000_000_000.0);
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
    final ls = _effectiveLandSize;
    if (ls <= 0) return 5;
    return AppValidators.maxFloors(ls);
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
    // Luas bangunan diisi di Step 3, jadi di Step 2 hanya validasi kamar, lantai, dan style
    if (_bedrooms < 1) {
      _showError('Minimal 1 kamar tidur diperlukan');
      return false;
    }
    final maxBR = AppValidators.maxBedroomsForFloors(_floors);
    if (_bedrooms > maxBR) {
      _showError('Terlalu banyak kamar tidur untuk $_floors lantai (maks $maxBR)');
      return false;
    }
    final maxBath = AppValidators.maxBathroomsForBedrooms(_bedrooms);
    if (_bathrooms > maxBath) {
      _showError('Kamar mandi terlalu banyak (maks $maxBath untuk $_bedrooms kamar tidur)');
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
    if (_isCustomLand) {
      final p = double.tryParse(_customLandPanjangController.text) ?? 0;
      final l = double.tryParse(_customLandLebarController.text) ?? 0;
      if (p <= 0 || l <= 0) {
        _showError('Masukkan panjang dan lebar tanah untuk pilihan Custom');
        return false;
      }
      if (p > 200 || l > 200) {
        _showError('Panjang atau lebar tanah custom maksimal 200 meter');
        return false;
      }
    }

    final ls = _effectiveLandSize;
    final buildingSize = double.tryParse(_buildingSizeController.text.trim()) ?? 0.0;
    if (buildingSize <= 0) {
      _showError('Luas bangunan wajib diisi');
      return false;
    }
    if (buildingSize > _maxBuildingSize) {
      _showError(
        'Luas bangunan (${buildingSize.toStringAsFixed(0)} m²) tidak boleh '
        'melebihi ${_maxBuildingSize.toStringAsFixed(0)} m² '
        '(${ls <= 22222 ? "90% dari luas tanah" : "batas maksimum 20.000 m²"})',
      );
      return false;
    }

    final List<String> errors = AppValidators.validateBuildingSpecs(
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      buildingSize: buildingSize,
      landSizeM2: ls,
    );
    if (errors.isNotEmpty) {
      _showError(errors.first);
      return false;
    }

    if (_budget <= 0) {
      _showError('Tentukan budget proyek Anda');
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
  }

  /// Simpan data form saat ini ke Supabase sebagai draft, lalu keluar.
  Future<void> _saveDraftAndExit() async {
    setState(() {
      _isDrafting = true;
      _isConsulting = false;
    });

    final success = await context.read<ProjectCubit>().saveDraft(
      draftId: _editingDraftId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      budget: _budget,
      landSize: _effectiveLandSize,
      buildingSize: double.tryParse(_buildingSizeController.text) ?? 0.0,
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      houseStyle: _selectedStyle ?? '',
      location: _locationController.text.trim(),
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      landCustomPanjang: _isCustomLand
          ? (double.tryParse(_customLandPanjangController.text))
          : null,
      landCustomLebar: _isCustomLand
          ? (double.tryParse(_customLandLebarController.text))
          : null,
      imageFile: _selectedImageFile,
      pdfFile: _selectedPdfFile,
      imageUrls: _serverImageUrl != null ? [_serverImageUrl!] : [],
      referencePdfUrl: _serverPdfUrl,
    );

    if (!mounted) return;
    if (!success) {
      _showError('Gagal menyimpan draft. Coba lagi.');
    }
  }

  /// Simpan draf lalu kembalikan sinyal 'route_to_consultation' ke pemanggil
  /// agar navigasi tab dapat langsung beralih ke tab Konsultasi.
  Future<void> _saveDraftAndConsultArchitect() async {
    setState(() {
      _isDrafting = true;
      _isConsulting = true;
    });

    final success = await context.read<ProjectCubit>().saveDraft(
      draftId: _editingDraftId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      budget: _budget,
      landSize: _effectiveLandSize,
      buildingSize: double.tryParse(_buildingSizeController.text) ?? 0.0,
      floors: _floors,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      houseStyle: _selectedStyle ?? '',
      location: _locationController.text.trim(),
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      landCustomPanjang: _isCustomLand
          ? (double.tryParse(_customLandPanjangController.text))
          : null,
      landCustomLebar: _isCustomLand
          ? (double.tryParse(_customLandLebarController.text))
          : null,
      imageFile: _selectedImageFile,
      pdfFile: _selectedPdfFile,
      imageUrls: _serverImageUrl != null ? [_serverImageUrl!] : [],
      referencePdfUrl: _serverPdfUrl,
    );

    if (!mounted) return;
    if (!success) {
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
    final bool isCustom = template['isCustom'] == true;
    final double landSize = isCustom ? _customLandSize : (template['size'] as double);
    final int maxF = landSize > 0 ? AppValidators.maxFloors(landSize) : 5;
    final bool floorsAdjusted = landSize > 0 && _floors > maxF;

    setState(() {
      _selectedLand = template;
      if (!isCustom) {
        _minBudget = template['basePrice'] as double;
        _budget = template['basePrice'] as double;
        if (_floors > maxF) _floors = maxF;
      } else {
        // Custom: reset budget agar user isi dari input
        _minBudget = 0;
        _budget = 0;
      }
      _clampRooms();
    });

    if (floorsAdjusted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Jumlah lantai disesuaikan menjadi $maxF '
            'lantai untuk tanah ${landSize.toStringAsFixed(0)} m²',
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
      imageQuality: 60,
    );
    if (image != null) {
      final file = File(image.path);
      final sizeMB = file.lengthSync() / (1024 * 1024);
      if (sizeMB > 5.0) {
        if (mounted) _showError('Ukuran foto maksimal 5MB!');
        return;
      }
      setState(() => _selectedImageFile = file);
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

    setState(() {
      _isDrafting = false;
      _isConsulting = false;
    });

    // ── MODE EDIT PROYEK AKTIF ──
    if (widget.isEditMode && _editingDraftId != null) {
      final success = await context.read<ProjectCubit>().updateProject(
        projectId: _editingDraftId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        budget: _budget,
        landSize: _effectiveLandSize,
        buildingSize: double.tryParse(_buildingSizeController.text) ?? 0.0,
        floors: _floors,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        houseStyle: _selectedStyle!,
        location: _locationController.text.trim(),
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        imageFile: _selectedImageFile,
        pdfFile: _selectedPdfFile,
        imageUrls: _serverImageUrl != null ? [_serverImageUrl!] : [],
        referencePdfUrl: _serverPdfUrl,
      );
      if (!mounted) return;
      if (!success) {
        _showError('Gagal memperbarui proyek. Coba lagi.');
      }
      return;
    }

    // ── MODE BUAT PROYEK BARU ──
    bool success = await context.read<ProjectCubit>().createProject(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      budget: _budget,
      landSize: _effectiveLandSize,
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
      imageUrls: _serverImageUrl != null ? [_serverImageUrl!] : [],
      referencePdfUrl: _serverPdfUrl,
    );

    if (!mounted) return;

    if (success) {
      // Hapus draft lama jika ini adalah lanjutan dari draft
      if (_editingDraftId != null) {
        await context.read<ProjectCubit>().deleteDraft(_editingDraftId!);
      }
    } else {
      _showError('Gagal membuat proyek. Coba lagi.');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _buildingSizeController.removeListener(_onBuildingSizeChanged);
    _buildingSizeController.dispose();
    _locationController.dispose();
    _customLandPanjangController.removeListener(_onCustomLandChanged);
    _customLandLebarController.removeListener(_onCustomLandChanged);
    _customLandPanjangController.dispose();
    _customLandLebarController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final projectState = context.watch<ProjectCubit>().state;
    final isLoading = projectState is ProjectLoading;

    return BlocListener<ProjectCubit, ProjectState>(
      listener: (context, state) {
        if (state is ProjectSuccess) {
          if (_isConsulting) {
            _isConsulting = false;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Draft Tersimpan!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Proyek kamu berhasil disimpan ke draft. Kamu akan diarahkan ke halaman Konsultasi Arsitek.',
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx); // pop dialog
                      Navigator.pop(context, 'route_to_consultation'); // pop screen with route info
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AnimatedSuccessDialog(
                message: widget.isEditMode
                    ? 'Proyek berhasil diperbarui! ✅'
                    : (_isDrafting ? 'Draft berhasil disimpan! 📝' : 'Proyek berhasil dipublikasikan! 🚀'),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context); // pop dialog
                Navigator.pop(context); // pop screen
              }
            });
          }
        }
      },
      child: Scaffold(
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
                    Text(
                      widget.isEditMode ? "Edit Proyek" : "Buat Proyek Baru",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Icon bookmark → hanya tampil di mode buat baru (bukan edit)
                    if (!widget.isEditMode)
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
                      )
                    else
                      const SizedBox(width: 48), // placeholder agar judul tetap center
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
          CreateProjectConstraintInfo(
            floors: _floors,
            maxBedrooms: _maxBedrooms,
            bedrooms: _bedrooms,
            maxBathrooms: _maxBathrooms,
            effectiveLandSize: _effectiveLandSize,
            maxFloors: _maxFloors,
          ),
          const SizedBox(height: 20),
          CreateProjectCounterCard(
            title: "Jumlah Lantai",
            icon: Icons.layers_outlined,
            value: _floors,
            onChanged: _onFloorsChanged,
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
                child: CreateProjectCounterCard(
                  title: "Kamar Tidur",
                  icon: Icons.bed_outlined,
                  value: _bedrooms,
                  onChanged: _onBedroomsChanged,
                  min: 0,
                  max: _maxBedrooms,
                  hint: 'Maks $_maxBedrooms (${_floors} lantai × 4)',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CreateProjectCounterCard(
                  title: "Kamar Mandi",
                  icon: Icons.bathtub_outlined,
                  value: _bathrooms,
                  onChanged: (val) => setState(() => _bathrooms = val),
                  min: 0,
                  max: _maxBathrooms,
                  hint: 'Maks $_maxBathrooms (kamar tidur + 1)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle("Tipe Rumah"),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: _houseStyles.map((style) => CreateProjectHouseStyleCard(
              style: style,
              isSelected: _selectedStyle == style,
              onTap: () => setState(() => _selectedStyle = style),
            )).toList(),
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
            items: [
              ..._landTemplates.map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t['label'], overflow: TextOverflow.ellipsis),
                ),
              ),
              // Opsi Custom paling bawah
              const DropdownMenuItem(
                value: _customTemplate,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: Color(0xFF8B2B0F)),
                    SizedBox(width: 8),
                    Text(
                      'Custom (Masukkan sendiri)',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8B2B0F)),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: _onTemplateSelected,
          ),

          // ── Input custom panjang × lebar (hanya muncul jika Custom dipilih) ──
          if (_isCustomLand) ...[
            const SizedBox(height: 12),
            _buildCustomLandInput(),
          ],

          if (_selectedLand != null && (_isCustomLand ? _customLandSize > 0 : true)) ...[
            const SizedBox(height: 12),
            _buildLandLimitInfo(),
          ],

          const SizedBox(height: 24),
          _buildSectionTitle("Luas Bangunan"),
          _buildSmoothTextField(
            _buildingSizeController,
            _effectiveLandSize > 0
                ? 'Maks ${_maxBuildingSize.toStringAsFixed(0)} m² (maks 20.000m²)'
                : 'Contoh: 120',
            Icons.square_foot_rounded,
            isNumber: true,
            suffix: "m²",
          ),
          if (_effectiveLandSize > 0) ...() {
            final inputVal = double.tryParse(_buildingSizeController.text) ?? 0.0;
            final maxB = _maxBuildingSize;
            final isOver = inputVal > 0 && inputVal > maxB;
            return [
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isOver ? Colors.red.shade50 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOver ? Colors.red.shade200 : Colors.teal.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      size: 14,
                      color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isOver
                            ? 'Melebihi batas! Maks ${maxB.toStringAsFixed(0)} m² (90% tanah / maks 20.000m²)'
                            : 'Batas luas bangunan: ${maxB.toStringAsFixed(0)} m² (90% tanah / maks 20.000m²)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOver ? Colors.red.shade700 : Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          }(),

          const SizedBox(height: 32),

          _buildSectionTitle("Budget Anda"),
          _buildBudgetCard(),
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
                        color: Colors.white.withValues(alpha: 0.95),
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
            "Foto Sampul Proyek (Maks 5MB, terkompresi otomatis)",
          ),
          _buildUploadBox(
            title: _selectedImageFile != null
                ? _selectedImageFile!.path.split('/').last
                : (_serverImageUrl != null
                    ? _serverImageUrl!.split('/').last
                    : "Unggah Foto (.jpg, .png)"),
            icon: Icons.add_photo_alternate_outlined,
            isUploaded: _selectedImageFile != null || _serverImageUrl != null,
            onTap: _pickImage,
          ),
          if (_selectedImageFile != null || _serverImageUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _selectedImageFile = null;
                _serverImageUrl = null;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Hapus foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle("Dokumen Pendukung / Denah (Max 2MB)"),
          _buildUploadBox(
            title: _selectedPdfFile != null
                ? _selectedPdfFile!.path.split('/').last
                : (_serverPdfUrl != null
                    ? _serverPdfUrl!.split('/').last
                    : "Unggah PDF Referensi (.pdf)"),
            icon: Icons.description_outlined,
            isUploaded: _selectedPdfFile != null || _serverPdfUrl != null,
            onTap: _pickPdf,
          ),
          if (_selectedPdfFile != null || _serverPdfUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _selectedPdfFile = null;
                _serverPdfUrl = null;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Hapus PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          // ── Tombol konsultasi arsitek — card premium ──
          _buildArchitectConsultButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // REUSABLE UI COMPONENTS
  // ════════════════════════════════════════════════════

  /// Input dua kolom panjang × lebar untuk custom tanah
  Widget _buildCustomLandInput() {
    final ls = _customLandSize;
    final minBudget = _autoMinBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info formula
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8B2B0F).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8B2B0F).withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF8B2B0F)),
                  SizedBox(width: 6),
                  Text('Rumus Estimasi Budget',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B2B0F))),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Luas Tanah × 60% × Rp 4.000.000 = Budget Minimum',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              if (ls > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${ls.toStringAsFixed(0)} m² × 60% × Rp4jt = ${AppFormatters.formatRupiah(minBudget)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B2B0F)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Input panjang dan lebar
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customLandPanjangController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Panjang (m)',
                  hintText: 'cth: 10 (maks 200)',
                  prefixIcon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            ),
            Expanded(
              child: TextFormField(
                controller: _customLandLebarController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Lebar (m)',
                  hintText: 'cth: 15 (maks 200)',
                  prefixIcon: const Icon(Icons.swap_vert_rounded, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
            ),
          ],
        ),
        if (ls > 0) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'Luas Tanah: ${ls.toStringAsFixed(1)} m²',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  /// Budget card dengan slider dan info minimum
  Widget _buildBudgetCard() {
    final effectiveMin = _isCustomLand ? _autoMinBudget : _minBudget;
    final bool canUse = _selectedLand != null && (!_isCustomLand || _customLandSize > 0);

    final double actualMin = effectiveMin > 0 ? effectiveMin : 0.0;
    final double maxB = _maxBudget;
    final double actualMax = maxB > actualMin ? maxB : actualMin + 1_000_000.0;

    // Clamp budget to make sure it's within range
    final double sliderVal = _budget.clamp(actualMin, actualMax);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canUse ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                canUse && sliderVal > 0 ? AppFormatters.formatRupiah(sliderVal) : 'Pilih ukuran tanah dulu',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: canUse && sliderVal > 0 ? AppColors.primary : Colors.black38,
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0, elevation: 4),
              ),
              child: Slider(
                value: canUse && actualMin > 0 ? sliderVal : 0.0,
                min: canUse && actualMin > 0 ? actualMin : 0.0,
                max: canUse && actualMin > 0 ? actualMax : 1_000_000.0,
                divisions: 100,
                onChanged: canUse && actualMin > 0 ? (val) => setState(() => _budget = val) : null,
              ),
            ),
            if (canUse && effectiveMin > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Minimum: ${AppFormatters.formatRupiah(effectiveMin)} '
                  '(${_effectiveLandSize.toStringAsFixed(0)} m² × 60% × Rp 4jt)',
                  style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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

  Widget _buildLandLimitInfo() {
    final double landSize = _effectiveLandSize;
    if (landSize <= 0) return const SizedBox.shrink();
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
                  ? 'Tanah ${landSize.toStringAsFixed(0)} m²: maks $maxF lantai — Anda memilih $_floors lantai ✓'
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
          color: const Color(0xFF8B2B0F).withValues(alpha: 0.7),
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
          color: const Color(0xFF8B2B0F).withValues(alpha: 0.8),
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
              ? const Color(0xFF8B2B0F).withValues(alpha: 0.05)
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


  /// Card premium untuk konsultasi arsitek
  Widget _buildArchitectConsultButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _saveDraftAndConsultArchitect,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B2B0F), Color(0xFFC95E36)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B2B0F).withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // Icon arsitek dalam lingkaran putih semi-transparan
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.architecture_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Teks judul + subjudul
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konsultasi dengan Arsitek',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Simpan draft & hubungi arsitek untuk desain profesional',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Panah kanan
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
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
