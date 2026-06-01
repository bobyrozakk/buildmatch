import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/providers/vendor_provider.dart';
import '../../../data/models/portfolio_model.dart';
import '../../../data/models/certification_model.dart';
import '../../../core/constants/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.backgroundCream,

      appBar: AppBar(
        backgroundColor:
            AppColors.backgroundCream,
        elevation: 0,
        leading:
            const BackButton(color: Colors.black87),

        title: const Text(
          'Kelola Profil',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),

        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              Colors.grey,
          indicatorColor:
              AppColors.primary,
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

// =======================================================
// TAB PROFIL
// =======================================================

class _TabProfilForm extends StatefulWidget {
  const _TabProfilForm();

  @override
  State<_TabProfilForm> createState() =>
      _TabProfilFormState();
}

class _TabProfilFormState
    extends State<_TabProfilForm> {

  final _nameCtrl =
      TextEditingController();

  final _companyCtrl =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    final user =
        Supabase.instance.client.auth.currentUser;

    _nameCtrl.text =
        user?.userMetadata?['name'] ?? '';

    _companyCtrl.text =
        user?.userMetadata?['company_name'] ??
            '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {

    final provider =
        Provider.of<VendorProvider>(
      context,
      listen: false,
    );

    final success =
        await provider.updateVendorProfile(
      name: _nameCtrl.text.trim(),
      companyName:
          _companyCtrl.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: success
            ? Colors.green
            : Colors.red,
        content: Text(
          success
              ? 'Profil berhasil diupdate'
              : 'Gagal update profil',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final loading =
        context.watch<VendorProvider>()
            .isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: Column(
              children: [

                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText:
                        'Nama Lengkap',
                    filled: true,
                    fillColor:
                        AppColors.cardCream,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _companyCtrl,
                  decoration: InputDecoration(
                    labelText:
                        'Nama Perusahaan',
                    filled: true,
                    fillColor:
                        AppColors.cardCream,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        loading ? null : _save,

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),

                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Simpan Profil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// TAB PORTOFOLIO
// =======================================================

class _TabPortoForm extends StatefulWidget {
  const _TabPortoForm();

  @override
  State<_TabPortoForm> createState() =>
      _TabPortoFormState();
}

class _TabPortoFormState
    extends State<_TabPortoForm> {

  final _titleCtrl =
      TextEditingController();

  final _yearCtrl =
      TextEditingController();

  File? _imageFile;

  late Future<List<PortfolioModel>>
      _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future =
        Provider.of<VendorProvider>(
      context,
      listen: false,
    ).fetchPortfolios();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {

    final picker = ImagePicker();

    final picked =
        await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }
  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data terlebih dahulu'),
        ),
      );
      return;
    }

    final provider = Provider.of<VendorProvider>(
      context,
      listen: false,
    );

    try {
      final success = await provider.addPortfolio(
        title: _titleCtrl.text.trim(),
        year: _yearCtrl.text.trim(),
        imageFile: _imageFile,
      );

      if (!mounted) return;

      if (success) {
        _titleCtrl.clear();
        _yearCtrl.clear();

        setState(() {
          _imageFile = null;
          _load();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Portofolio berhasil ditambah'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal menambah portofolio. Pastikan storage "portfolios" terkonfigurasi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal menyimpan: $e'),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {

    final loading =
        context.watch<VendorProvider>()
            .isLoading;

    return FutureBuilder<List<PortfolioModel>>(
      future: _future,

      builder: (_, snapshot) {

        final portfolios =
            snapshot.data ?? [];

        return SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            children: [

              GestureDetector(
                onTap: _pickImage,

                child: Container(
                  height: 170,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(
                              _imageFile!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),

                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [

                            Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                              size: 50,
                              color: Colors.black45,
                            ),

                            SizedBox(height: 10),

                            Text(
                              'Upload Foto Portofolio',
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText:
                      'Judul Proyek',
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _yearCtrl,
                keyboardType:
                    TextInputType.number,

                decoration: InputDecoration(
                  labelText:
                      'Tahun Selesai',
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      loading ? null : _save,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Tambah Portofolio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Daftar Portofolio',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              ...portfolios.map(
                (item) => Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 14,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      child: item.imageUrl !=
                              null
                          ? Image.network(
                              item.imageUrl!,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 55,
                              height: 55,
                              color: Colors.grey,
                            ),
                    ),

                    title: Text(
                      item.title,
                    ),

                    subtitle: Text(
                      item.year,
                    ),

                    trailing:
                        PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Hapus',
                          ),
                        ),
                      ],

                      onSelected:
                          (value) async {

                        if (value ==
                            'delete') {

                          final provider =
                              Provider.of<
                                  VendorProvider>(
                            context,
                            listen: false,
                          );

                          await provider
                              .deletePortfolio(
                            item.id!,
                          );

                          setState(() {
                            _load();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =======================================================
// TAB SERTIFIKASI
// =======================================================

class _TabSertifForm extends StatefulWidget {
  const _TabSertifForm();

  @override
  State<_TabSertifForm> createState() =>
      _TabSertifFormState();
}

class _TabSertifFormState
    extends State<_TabSertifForm> {

  final _titleCtrl =
      TextEditingController();

  final _issuerCtrl =
      TextEditingController();

  late Future<List<CertificationModel>>
      _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future =
        Provider.of<VendorProvider>(
      context,
      listen: false,
    ).fetchCertifications();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _issuerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _issuerCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data terlebih dahulu')),
      );
      return;
    }

    final provider = Provider.of<VendorProvider>(context, listen: false);

    try {
      final success = await provider.addCertification(
        title: _titleCtrl.text.trim(),
        issuer: _issuerCtrl.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _titleCtrl.clear();
        _issuerCtrl.clear();
        setState(() {
          _load();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Sertifikasi berhasil ditambah'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal menambah sertifikasi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Gagal menyimpan: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final loading =
        context.watch<VendorProvider>()
            .isLoading;

    return FutureBuilder<
        List<CertificationModel>>(
      future: _future,

      builder: (_, snapshot) {

        final certs =
            snapshot.data ?? [];

        return SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            children: [

              TextField(
                controller: _titleCtrl,

                decoration: InputDecoration(
                  labelText:
                      'Nama Sertifikat',
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _issuerCtrl,

                decoration: InputDecoration(
                  labelText:
                      'Penerbit',
                  filled: true,
                  fillColor:
                      Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      loading ? null : _save,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Tambah Sertifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  'Daftar Sertifikasi',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              ...certs.map(
                (cert) => Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 14,
                  ),

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Row(
                    children: [

                      const Icon(
                        Icons
                            .verified_outlined,
                        color:
                            AppColors.primary,
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [

                            Text(
                              cert.title,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              cert.issuer,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value:
                                'delete',
                            child: Text(
                              'Hapus',
                            ),
                          ),
                        ],

                        onSelected:
                            (value) async {

                          if (value ==
                              'delete') {

                            final provider =
                                Provider.of<
                                    VendorProvider>(
                              context,
                              listen:
                                  false,
                            );

                            await provider
                                .deleteCertification(
                              cert.id!,
                            );

                            setState(() {
                              _load();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}