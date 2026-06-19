import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:buildmatch/modules/client/logic/vendor/vendor_cubit.dart';
import 'package:buildmatch/modules/client/logic/vendor/vendor_state.dart';
import 'package:buildmatch/core/constants/colors.dart';
import 'package:buildmatch/ui/shared/screens/image_cropper_screen.dart';
import 'package:buildmatch/ui/shared/widgets/animated_success_dialog.dart';

import 'widgets/edit_profile_profil_tab.dart';
import 'widgets/edit_profile_porto_tab.dart';
import 'widgets/edit_profile_sertifikasi_tab.dart';

class EditProfileScreen extends StatefulWidget {
  final int initialTab;
  const EditProfileScreen({super.key, this.initialTab = 0});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Profil controllers
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _nibCtrl = TextEditingController();
  final _npwpCtrl = TextEditingController();

  // Avatar State
  File? _avatarFile;
  String? _currentAvatarUrl;

  // Portofolio State
  final _portoTitleCtrl = TextEditingController();
  final _portoYearCtrl = TextEditingController();
  File? _portoImageFile;

  // Sertifikasi State
  final _certTitleCtrl = TextEditingController();
  final _certIssuerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadInitialData();
  }

  void _loadInitialData() {
    final vendorCubit = context.read<VendorCubit>();
    final state = vendorCubit.state;
    if (state is VendorLoaded) {
      final profile = state.vendorProfile;
      if (profile != null) {
        _nameCtrl.text = profile.name;
        _companyCtrl.text = profile.companyName ?? '';
        _nibCtrl.text = profile.nib ?? '';
        _npwpCtrl.text = profile.npwp ?? '';
        _currentAvatarUrl = profile.avatarUrl;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _nibCtrl.dispose();
    _npwpCtrl.dispose();
    _portoTitleCtrl.dispose();
    _portoYearCtrl.dispose();
    _certTitleCtrl.dispose();
    _certIssuerCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _pickPortoImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (picked != null) {
      setState(() {
        _portoImageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _companyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Lengkap & Nama Perusahaan wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<VendorCubit>();
    final success = await provider.updateVendorProfile(
      name: _nameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      nib: _nibCtrl.text.trim(),
      npwp: _npwpCtrl.text.trim(),
      avatarFile: _avatarFile,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AnimatedSuccessDialog(
            message: 'Profil berhasil diperbarui!',
          ),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addPortfolio() async {
    if (_portoTitleCtrl.text.isEmpty || _portoImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi judul dan foto portofolio!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<VendorCubit>();
    try {
      final success = await provider.addPortfolio(
        title: _portoTitleCtrl.text.trim(),
        year: _portoYearCtrl.text.trim(),
        imageFile: _portoImageFile,
      );

      if (success && mounted) {
        _portoTitleCtrl.clear();
        _portoYearCtrl.clear();
        setState(() {
          _portoImageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portofolio berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCertification() async {
    if (_certTitleCtrl.text.isEmpty || _certIssuerCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Sertifikat & Penerbit wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<VendorCubit>();
    try {
      final success = await provider.addCertification(
        title: _certTitleCtrl.text.trim(),
        issuer: _certIssuerCtrl.text.trim(),
      );

      if (success && mounted) {
        _certTitleCtrl.clear();
        _certIssuerCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sertifikasi berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola Profil',
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
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Portofolio'),
            Tab(text: 'Sertifikasi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                EditProfileProfilTab(
                  nameCtrl: _nameCtrl,
                  companyCtrl: _companyCtrl,
                  nibCtrl: _nibCtrl,
                  npwpCtrl: _npwpCtrl,
                  avatarFile: _avatarFile,
                  currentAvatarUrl: _currentAvatarUrl,
                  onPickAvatar: _pickAvatar,
                ),
                EditProfilePortoTab(
                  portoTitleCtrl: _portoTitleCtrl,
                  portoYearCtrl: _portoYearCtrl,
                  portoImageFile: _portoImageFile,
                  onPickPortoImage: _pickPortoImage,
                  onAddPortfolio: _addPortfolio,
                ),
                EditProfileSertifikasiTab(
                  certTitleCtrl: _certTitleCtrl,
                  certIssuerCtrl: _certIssuerCtrl,
                  onAddCertification: _addCertification,
                ),
              ],
            ),
    );
  }
}