import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/architect_provider.dart';
import '../../shared/screens/map_picker_screen.dart';
import '../../shared/screens/image_cropper_screen.dart';
import '../../shared/widgets/animated_success_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Profil controllers
  final _nameCtrl = TextEditingController();
  final _studioCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _status = "Tersedia untuk Proyek";

  // Avatar & Map Picker State
  File? _avatarFile;
  String? _currentAvatarUrl;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      final file = File(picked.path);
      if (!mounted) return;
      final croppedFile = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageCropperScreen(imageFile: file),
        ),
      );
      if (croppedFile != null) {
        setState(() {
          _avatarFile = croppedFile;
        });
      }
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'BuildMatch/1.0 (com.buildmatch.app)',
          'Accept-Language': 'id,en',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          final parts = displayName.split(', ');
          return parts.take(3).join(', ');
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return null;
  }

  Future<void> _selectLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is LatLng) {
      setState(() => _isLoading = true);
      final address = await _reverseGeocode(result.latitude, result.longitude);
      setState(() => _isLoading = false);

      if (address != null) {
        _locationCtrl.text = address;
      } else {
        _locationCtrl.text =
            "${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}";
      }
    }
  }

  // Spesialisasi selected tags
  final Set<String> _selectedStyles = {};
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedSkills = {};

  final List<String> _architecturalStyles = [
    "Minimalis",
    "Modern Tropis",
    "Industrial",
    "Skandinavia",
    "Klasik Kontemporer",
    "Brutalis",
  ];
  final List<String> _projectTypes = [
    "Rumah Tinggal",
    "Kafe & Resto",
    "Kantor Modern",
    "Villa Resort",
    "Renovasi",
  ];
  final List<String> _technicalSkills = [
    "Struktur Baja",
    "Rumah Hemat Energi",
    "Desain Interior Terpadu",
    "Lansekap",
    "BIM Modeling",
    "Green Building",
    "Smart Home Integration",
  ];

  // Sertifikasi state
  final _certTitleCtrl = TextEditingController();
  final _certRegCtrl = TextEditingController();
  final _certIssuedCtrl = TextEditingController();
  final _certExpiryCtrl = TextEditingController();

  File? _certFile;
  String? _certFileName;

  List<Map<String, String>> _certsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final architectProvider = Provider.of<ArchitectProvider>(
        context,
        listen: false,
      );
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final details = await architectProvider.fetchArchitectDetails(userId);
        if (details != null && mounted) {
          final profile = details['profile'] as ProfileModel;
          _nameCtrl.text = profile.name;
          _studioCtrl.text = profile.companyName ?? '';
          _expCtrl.text = profile.experienceYears ?? '';
          _bioCtrl.text = details['bio'] ?? '';
          _locationCtrl.text = details['location'] ?? '';
          _currentAvatarUrl = profile.avatarUrl;
          if (details['status'] != null &&
              details['status'].toString().isNotEmpty) {
            _status = details['status'];
          }

          final specializations =
              details['specializations'] as Map<String, dynamic>? ?? {};
          _selectedStyles.clear();
          _selectedTypes.clear();
          _selectedSkills.clear();

          if (specializations['styles'] != null) {
            _selectedStyles.addAll(
              List<String>.from(specializations['styles']),
            );
          }
          if (specializations['project_types'] != null) {
            _selectedTypes.addAll(
              List<String>.from(specializations['project_types']),
            );
          }
          if (specializations['technical_skills'] != null) {
            _selectedSkills.addAll(
              List<String>.from(specializations['technical_skills']),
            );
          }

          final certs = await architectProvider.fetchCertifications(userId);
          if (mounted) {
            _certsList = certs
                .map(
                  (e) {
                    String regNo = e.issuer;
                    String expiry = '-';
                    if (e.issuer.startsWith('{')) {
                      try {
                        final data = jsonDecode(e.issuer);
                        regNo = data['registration_number'] ?? '';
                        expiry = data['expiry_date'] ?? '-';
                      } catch (_) {}
                    }
                    return {
                      'id': e.id ?? '',
                      'title': e.title,
                      'no': regNo,
                      'expiry': expiry,
                      'color': 'blue',
                    };
                  },
                )
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Error load profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _studioCtrl.dispose();
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _locationCtrl.dispose();
    _certTitleCtrl.dispose();
    _certRegCtrl.dispose();
    _certIssuedCtrl.dispose();
    _certExpiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _isLoading = true);

    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final errorMsg = await provider.updateProfile(
      name: _nameCtrl.text,
      studioName: _studioCtrl.text,
      bio: _bioCtrl.text,
      experience: _expCtrl.text,
      location: _locationCtrl.text,
      status: _status,
      styles: _selectedStyles.toList(),
      projectTypes: _selectedTypes.toList(),
      technicalSkills: _selectedSkills.toList(),
      avatarFile: _avatarFile,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMsg == null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AnimatedSuccessDialog(message: 'Profil berhasil diperbarui!'),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _addCertification() async {
    if (_certTitleCtrl.text.isEmpty || _certRegCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Sertifikasi & Nomor Registrasi wajib diisi!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final success = await provider.addCertification(
      title: _certTitleCtrl.text.trim(),
      registrationNumber: _certRegCtrl.text.trim(),
      issuedDate: _certIssuedCtrl.text.trim(),
      expiryDate: _certExpiryCtrl.text.trim(),
      documentFile: _certFile,
    );

    if (success && mounted) {
      _certTitleCtrl.clear();
      _certRegCtrl.clear();
      _certIssuedCtrl.clear();
      _certExpiryCtrl.clear();
      _certFile = null;
      _certFileName = null;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final certs = await provider.fetchCertifications(userId);
        if (mounted) {
          setState(() {
            _certsList = certs
                .map(
                  (e) {
                    String regNo = e.issuer;
                    String expiry = '-';
                    if (e.issuer.startsWith('{')) {
                      try {
                        final data = jsonDecode(e.issuer);
                        regNo = data['registration_number'] ?? '';
                        expiry = data['expiry_date'] ?? '-';
                      } catch (_) {}
                    }
                    return {
                      'id': e.id ?? '',
                      'title': e.title,
                      'no': regNo,
                      'expiry': expiry,
                      'color': 'blue',
                    };
                  },
                )
                .toList();
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikasi berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambahkan sertifikasi.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCert(String id) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ArchitectProvider>(context, listen: false);
    final success = await provider.deleteCertification(id);

    if (success && mounted) {
      setState(() {
        _certsList.removeWhere((element) => element['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikasi berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
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
          'Edit Profil',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F2A0C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8F2A0C),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF8F2A0C),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Spesialisasi'),
            Tab(text: 'Sertifikasi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8F2A0C)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfilTab(),
                _buildSpesialisasiTab(),
                _buildSertifikasiTab(),
              ],
            ),
    );
  }

  // =========================================================
  // TAB 1: PROFIL
  // =========================================================
  Widget _buildProfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Center Avatar with camera icon
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5DCD3),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFF3EBE3),
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (_currentAvatarUrl != null &&
                                    _currentAvatarUrl!.isNotEmpty)
                              ? NetworkImage(_currentAvatarUrl!)
                                    as ImageProvider
                              : null,
                          child:
                              (_avatarFile == null &&
                                  (_currentAvatarUrl == null ||
                                      _currentAvatarUrl!.isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF8F2A0C),
                                  size: 48,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF8F2A0C),
                          radius: 14,
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildLabel('Nama Lengkap'),
          _buildTextField(_nameCtrl, 'Masukkan nama lengkap'),

          const SizedBox(height: 16),
          _buildLabel('Nama Studio'),
          _buildTextField(_studioCtrl, 'Masukkan nama studio'),

          const SizedBox(height: 16),
          _buildLabel('Bio Profesional'),
          _buildTextField(
            _bioCtrl,
            'Tulis deskripsi biografi profesional...',
            maxLines: 4,
          ),

          const SizedBox(height: 16),
          _buildLabel('Status'),
          _buildDropdown(_status, [
            "Tersedia untuk Proyek",
            "Penuh",
          ], (val) => setState(() => _status = val!)),

          const SizedBox(height: 16),
          _buildLabel('Pengalaman (Tahun)'),
          _buildTextField(
            _expCtrl,
            'Masukkan tahun pengalaman',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),
          _buildLabel('Lokasi'),
          _buildTextField(
            _locationCtrl,
            'Masukkan lokasi',
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: Colors.black45,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map_outlined, color: Color(0xFF8F2A0C)),
              onPressed: _selectLocationFromMap,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 2: SPESIALISASI
  // =========================================================
  Widget _buildSpesialisasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentukan Keahlian Anda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih kategori desain dan spesialisasi yang paling mewakili gaya kerja Anda. Ini membantu klien menemukan Anda lebih cepat.',
            style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
          ),

          const SizedBox(height: 24),
          _buildTagSelectorSection(
            'Gaya Arsitektur',
            Icons.architecture_outlined,
            _architecturalStyles,
            _selectedStyles,
          ),

          const SizedBox(height: 24),
          _buildTagSelectorSection(
            'Jenis Proyek',
            Icons.domain_outlined,
            _projectTypes,
            _selectedTypes,
          ),

          const SizedBox(height: 24),
          _buildTagSelectorSection(
            'Keahlian Teknis',
            Icons.construction_outlined,
            _technicalSkills,
            _selectedSkills,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 3: SERTIFIKASI
  // =========================================================
  Widget _buildSertifikasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sertifikasi & Lisensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola lisensi profesional dan sertifikasi untuk meningkatkan kepercayaan klien.',
            style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sertifikat Terunggah',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEBDB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_certsList.length} Aktif',
                  style: const TextStyle(
                    color: Color(0xFF8F2A0C),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildUploadedCertsList(),

          const SizedBox(height: 24),
          _buildTambahSertifikasiBox(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUploadedCertsList() {
    if (_certsList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Belum ada sertifikasi terunggah.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _certsList.map((cert) {
        final isOrange = cert['color'] == 'orange';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isOrange
                    ? const Color(0xFFFEEBDB)
                    : const Color(0xFFE2F0D9),
                child: Icon(
                  isOrange ? Icons.verified : Icons.verified_user_outlined,
                  color: isOrange ? const Color(0xFF8F2A0C) : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No: ${cert['no']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 8,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Berlaku hingga: ${cert['expiry']}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _deleteCert(cert['id']!),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8F2A0C),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8F2A0C),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _pickCertFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _certFile = File(result.files.single.path!);
          _certFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking cert file: $e");
    }
  }

  Widget _buildTambahSertifikasiBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DCD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF8F2A0C),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Tambah Sertifikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('Nama Sertifikat / Lisensi'),
          _buildTextField(_certTitleCtrl, 'Contoh: Arsitek Madya IAI'),

          const SizedBox(height: 12),
          _buildLabel('Nomor Registrasi'),
          _buildTextField(_certRegCtrl, 'Masukkan nomor registrasi resmi'),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tanggal Terbit'),
                    GestureDetector(
                      onTap: () => _selectDate(context, _certIssuedCtrl),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          _certIssuedCtrl,
                          'Pilih Tanggal',
                          suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8F2A0C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Masa Berlaku'),
                    GestureDetector(
                      onTap: () => _selectDate(context, _certExpiryCtrl),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          _certExpiryCtrl,
                          'Pilih Tanggal',
                          suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8F2A0C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildLabel('Unggah Dokumen (PDF/JPG)'),
          GestureDetector(
            onTap: _pickCertFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCF8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5DCD3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF8F2A0C),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _certFileName ?? 'Klik untuk memilih file dokumen',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Maksimal file 5MB (PDF/JPG/PNG)',
                    style: TextStyle(color: Colors.black38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(
                Icons.save_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Simpan Sertifikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              onPressed: _addCertification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F2A0C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8F2A0C)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
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
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black54,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTagSelectorSection(
    String sectionTitle,
    IconData iconData,
    List<String> tags,
    Set<String> selectionSet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconData, color: const Color(0xFF8F2A0C), size: 18),
            const SizedBox(width: 8),
            Text(
              sectionTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectionSet.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectionSet.remove(tag);
                  } else {
                    selectionSet.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8F2A0C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8F2A0C)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
