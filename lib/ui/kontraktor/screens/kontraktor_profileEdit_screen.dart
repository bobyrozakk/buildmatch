import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/vendor_provider.dart';
import '../../../core/constants/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Edit Profil & Portofolio', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Portofolio'),
            Tab(text: 'Sertifikasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TabProfilForm(),
          _TabPortoForm(),
          _TabSertifForm(),
        ],
      ),
    );
  }
}

// ==========================================
// 1. TAB PROFIL (EDIT NAMA & PERUSAHAAN)
// ==========================================
class _TabProfilForm extends StatefulWidget {
  const _TabProfilForm();
  @override
  State<_TabProfilForm> createState() => _TabProfilFormState();
}

class _TabProfilFormState extends State<_TabProfilForm> {
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Tarik data sementara dari auth metadata yang lagi login
    final user = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text = user?.userMetadata?['name'] ?? '';
    _companyCtrl.text = user?.userMetadata?['company_name'] ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  void _simpanProfil() async {
    final provider = Provider.of<VendorProvider>(context, listen: false);
    bool success = await provider.updateVendorProfile(name: _nameCtrl.text, companyName: _companyCtrl.text);
    
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diupdate!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal update profil!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VendorProvider>().isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: 'Nama Lengkap', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _companyCtrl,
            decoration: InputDecoration(labelText: 'Nama Perusahaan', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _simpanProfil,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 2. TAB PORTOFOLIO (UPLOAD FOTO HASIL KERJA)
// ==========================================
class _TabPortoForm extends StatefulWidget {
  const _TabPortoForm();
  @override
  State<_TabPortoForm> createState() => _TabPortoFormState();
}

class _TabPortoFormState extends State<_TabPortoForm> {
  final _titleCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  File? _imageFile;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _simpanPorto() async {
    if (_titleCtrl.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Gambar wajib diisi!')));
      return;
    }
    final provider = Provider.of<VendorProvider>(context, listen: false);
    bool success = await provider.addPortfolio(title: _titleCtrl.text, year: _yearCtrl.text, imageFile: _imageFile);
    
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portofolio berhasil ditambahkan!'), backgroundColor: Colors.green));
      _titleCtrl.clear(); _yearCtrl.clear(); setState(() => _imageFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VendorProvider>().isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16), image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null),
              child: _imageFile == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 40, color: Colors.black45), Text('Upload Foto Proyek')]) : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'Judul Proyek', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          TextField(controller: _yearCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tahun Selesai (Misal: 2023)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _simpanPorto,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tambah Portofolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 3. TAB SERTIFIKASI (NAMBAH KEAHLIAN)
// ==========================================
class _TabSertifForm extends StatefulWidget {
  const _TabSertifForm();
  @override
  State<_TabSertifForm> createState() => _TabSertifFormState();
}

class _TabSertifFormState extends State<_TabSertifForm> {
  final _titleCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issuerCtrl.dispose();
    super.dispose();
  }

  void _simpanSertif() async {
    if (_titleCtrl.text.isEmpty || _issuerCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul dan Penerbit wajib diisi!')));
      return;
    }
    final provider = Provider.of<VendorProvider>(context, listen: false);
    bool success = await provider.addCertification(title: _titleCtrl.text, issuer: _issuerCtrl.text);
    
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sertifikasi berhasil ditambahkan!'), backgroundColor: Colors.green));
      _titleCtrl.clear(); _issuerCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VendorProvider>().isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'Nama Sertifikat (Misal: SKA Madya)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          TextField(controller: _issuerCtrl, decoration: InputDecoration(labelText: 'Penerbit (Misal: LPJK)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : _simpanSertif,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Tambah Sertifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}