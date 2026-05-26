import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/certification_model.dart';
import '../../../data/providers/architect_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Profil controllers
  final _nameCtrl = TextEditingController(text: "Ar. Hendra Wijaya, IAI");
  final _studioCtrl = TextEditingController(text: "Wijaya Architect Lab");
  final _bioCtrl = TextEditingController(
    text: "Berfokus pada penggabungan nilai tradisional nusantara dengan fungsionalitas modern. Berpengalaman lebih dari 12 tahun dalam desain hunian tropis yang ramah lingkungan."
  );
  final _expCtrl = TextEditingController(text: "12");
  final _locationCtrl = TextEditingController(text: "Jakarta Selatan, DKI Jakarta");
  String _status = "Tersedia untuk Proyek";

  // Spesialisasi selected tags (high-fidelity dummies)
  final Set<String> _selectedStyles = {"Modern Tropis"};
  final Set<String> _selectedTypes = {"Rumah Tinggal"};
  final Set<String> _selectedSkills = {"BIM Modeling"};

  final List<String> _architecturalStyles = ["Minimalis", "Modern Tropis", "Industrial", "Skandinavia", "Klasik Kontemporer", "Brutalis"];
  final List<String> _projectTypes = ["Rumah Tinggal", "Kafe & Resto", "Kantor Modern", "Villa Resort", "Renovasi"];
  final List<String> _technicalSkills = ["Struktur Baja", "Rumah Hemat Energi", "Desain Interior Terpadu", "Lansekap", "BIM Modeling", "Green Building", "Smart Home Integration"];

  // Sertifikasi state (dummy data)
  final _certTitleCtrl = TextEditingController();
  final _certRegCtrl = TextEditingController();
  final _certIssuedCtrl = TextEditingController();
  final _certExpiryCtrl = TextEditingController();
  
  List<Map<String, String>> _certsList = [
    {
      'id': '1',
      'title': 'Anggota Utama IAI',
      'no': '12.3456.78.90',
      'expiry': '12 Des 2025',
      'color': 'orange',
    },
    {
      'id': '2',
      'title': 'Green Building Council Indonesia',
      'no': 'GBCI-2023-998',
      'expiry': '30 Jan 2026',
      'color': 'blue',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _saveAll() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    });
  }

  void _addCertification() {
    if (_certTitleCtrl.text.isEmpty || _certRegCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Sertifikasi & Nomor Registrasi wajib diisi!')),
      );
      return;
    }

    setState(() {
      _certsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _certTitleCtrl.text.trim(),
        'no': _certRegCtrl.text.trim(),
        'expiry': _certExpiryCtrl.text.isEmpty ? '12 Des 2028' : _certExpiryCtrl.text.trim(),
        'color': 'blue',
      });
      _certTitleCtrl.clear();
      _certRegCtrl.clear();
      _certIssuedCtrl.clear();
      _certExpiryCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sertifikasi berhasil ditambahkan!'), backgroundColor: Colors.green),
    );
  }

  void _deleteCert(String id) {
    setState(() {
      _certsList.removeWhere((element) => element['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sertifikasi berhasil dihapus.'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F2A0C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8F2A0C),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF8F2A0C),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Spesialisasi'),
            Tab(text: 'Sertifikasi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8F2A0C)))
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
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5DCD3), width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 46,
                        backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF8F2A0C),
                        radius: 14,
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Ganti Foto Profil', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
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
          _buildTextField(_bioCtrl, 'Tulis deskripsi biografi profesional...', maxLines: 4),

          const SizedBox(height: 16),
          _buildLabel('Status'),
          _buildDropdown(_status, ["Tersedia untuk Proyek", "Penuh"], (val) => setState(() => _status = val!)),

          const SizedBox(height: 16),
          _buildLabel('Pengalaman (Tahun)'),
          _buildTextField(_expCtrl, 'Masukkan tahun pengalaman', keyboardType: TextInputType.number),

          const SizedBox(height: 16),
          _buildLabel('Lokasi'),
          _buildTextField(
            _locationCtrl, 
            'Masukkan lokasi', 
            prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.black45, size: 20)
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
          const Text('Tentukan Keahlian Anda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          const Text(
            'Pilih kategori desain dan spesialisasi yang paling mewakili gaya kerja Anda. Ini membantu klien menemukan Anda lebih cepat.',
            style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
          ),
          
          const SizedBox(height: 24),
          _buildTagSelectorSection('Gaya Arsitektur', Icons.architecture_outlined, _architecturalStyles, _selectedStyles),
          
          const SizedBox(height: 24),
          _buildTagSelectorSection('Jenis Proyek', Icons.domain_outlined, _projectTypes, _selectedTypes),

          const SizedBox(height: 24),
          _buildTagSelectorSection('Keahlian Teknis', Icons.construction_outlined, _technicalSkills, _selectedSkills),
          
          const SizedBox(height: 24),
          
          // Illustration Card matching screenshot (blueprint schematic & quote)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5DCD3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1503387762-592dedb8c260?w=500&q=80',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.55),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '"Arsitektur adalah tentang menciptakan ruang yang berbicara"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8F2A0C)),
                      foregroundColor: const Color(0xFF8F2A0C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100), // Premium dark orange
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
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
          const Text('Sertifikasi & Lisensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          const Text(
            'Kelola lisensi profesional dan sertifikasi untuk meningkatkan kepercayaan klien.', 
            style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4)
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sertifikat Terunggah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEBDB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_certsList.length} Aktif', 
                  style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 9, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildUploadedCertsList(),

          const SizedBox(height: 24),
          _buildTambahSertifikasiBox(),
          
          const SizedBox(height: 28),
          
          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8F2A0C)),
                      foregroundColor: const Color(0xFF8F2A0C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batalkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C1C08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Selesai & Update Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
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
          border: Border.all(color: Colors.grey.shade200)
        ),
        child: const Center(
          child: Text(
            'Belum ada sertifikasi terunggah.', 
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)
          )
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
                backgroundColor: isOrange ? const Color(0xFFFEEBDB) : const Color(0xFFE2F0D9),
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
                    Text(cert['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text('No: ${cert['no']}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 8, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text('Berlaku hingga: ${cert['expiry']}', style: const TextStyle(fontSize: 9, color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteCert(cert['id']!),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
              Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8F2A0C), size: 18),
              SizedBox(width: 8),
              Text('Tambah Sertifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
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
                    _buildTextField(_certIssuedCtrl, 'mm/dd/yyyy'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Masa Berlaku'),
                    _buildTextField(_certExpiryCtrl, 'mm/dd/yyyy'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildLabel('Unggah Dokumen (PDF/JPG)'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5DCD3), style: BorderStyle.solid),
            ),
            child: Column(
              children: const [
                Icon(Icons.cloud_upload_outlined, color: Color(0xFF8F2A0C), size: 24),
                SizedBox(height: 6),
                Text('Klik untuk memilih file atau seret ke sini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 2),
                Text('Maksimal file 5MB', style: TextStyle(color: Colors.black38, fontSize: 9)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 16),
              label: const Text('Simpan Sertifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _addCertification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F2A0C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 12)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, {
    int maxLines = 1, 
    TextInputType? keyboardType,
    Widget? prefixIcon
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: prefixIcon,
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

  Widget _buildTagSelectorSection(String sectionTitle, IconData iconData, List<String> tags, Set<String> selectionSet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconData, color: const Color(0xFF8F2A0C), size: 18),
            const SizedBox(width: 8),
            Text(sectionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8F2A0C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFF8F2A0C) : Colors.grey.shade300),
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
