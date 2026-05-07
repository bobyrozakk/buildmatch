import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller umum (semua role)
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Controller khusus Client
  final _nameController = TextEditingController();

  // Controller khusus Kontraktor
  final _companyNameController = TextEditingController();
  final _picNameController = TextEditingController();
  final _npwpController = TextEditingController();
  String? _npwpFileName; // Nama file foto NPWP yang dipilih
  File? _npwpFile; // File aktual NPWP

  // Controller khusus Arsitek
  final _straNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _straFileName;
  File? _straFile;

  bool get _isKontraktor => widget.role.toLowerCase() == 'kontraktor';
  bool get _isArsitek => widget.role.toLowerCase() == 'arsitek';

  // ========== Password Strength Logic ==========
  int _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  String _getStrengthLabel(int score) {
    switch (score) {
      case 0:
        return '';
      case 1:
        return 'Lemah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Kuat';
      case 4:
        return 'Sangat Kuat';
      default:
        return '';
    }
  }

  Color _getStrengthColor(int score) {
    switch (score) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return const Color(0xFF4CAF50);
      case 4:
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey.shade300;
    }
  }

  // ========== Submit ==========
  void _submit() async {
    final email = _emailController.text.trim();
    // Regex validasi format email agar tidak abal-abal
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format email tidak valid!'), backgroundColor: Colors.red));
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok!'), backgroundColor: Colors.red));
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter!'), backgroundColor: Colors.red));
      return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);

    // Tentukan nama berdasarkan role
    String name = _nameController.text.trim();
    if (_isKontraktor) name = _picNameController.text.trim();

    // LEMPAR SEMUA DATA TERMASUK FILE KE PROVIDER
    String? errorMsg = await provider.register(
      email: email,
      password: _passwordController.text,
      name: name,
      phone: "+62${_phoneController.text.trim()}",
      role: widget.role.toLowerCase(),
      companyName: _isKontraktor ? _companyNameController.text.trim() : null,
      picName: _isKontraktor ? _picNameController.text.trim() : null,
      npwp: _isKontraktor ? _npwpController.text.trim() : null,
      npwpFile: _isKontraktor ? _npwpFile : null, // <-- Kirim file NPWP
      straNumber: _isArsitek ? _straNumberController.text.trim() : null,
      experienceYears: _isArsitek ? _experienceController.text.trim() : null,
      straFile: _isArsitek ? _straFile : null, // <-- Kirim file STRA
    );

    if (!mounted) return;
    
    if (errorMsg == null) {
      // Jika sukses, masuk ke halaman Register Success
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => RegisterSuccessScreen(role: widget.role)),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    }
  }

  // ========== Pilih Foto NPWP ==========
  Future<void> _pickNpwpPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        final extension = image.name.split('.').last.toLowerCase();
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          setState(() {
            _npwpFile = File(image.path);
            _npwpFileName = image.name;
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hanya format JPG dan PNG yang didukung!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Pilih Sumber Foto",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickNpwpPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickNpwpPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final password = _passwordController.text;
    final strength = _getPasswordStrength(password);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2B0F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.architecture,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "BuildMatch",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2B0F),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Akun Baru",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masuk ke akun BuildMatch Anda",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // ========== FORM FIELDS BERDASARKAN ROLE ==========
            if (_isKontraktor)
              ..._buildKontraktorFields()
            else if (_isArsitek)
              ..._buildArsitekFields()
            else
              ..._buildClientFields(),

            // ========== FIELD UMUM: EMAIL ==========
            const SizedBox(height: 16),
            _buildLabel("Email"),
            _buildFigmaTextField(
              _emailController,
              "contoh@gmail.com",
              Icons.email_outlined,
            ),

            // ========== FIELD UMUM: PASSWORD ==========
            const SizedBox(height: 16),
            _buildLabel("Password"),
            _buildFigmaTextField(
              _passwordController,
              "Min. 8 karakter",
              Icons.lock_outline,
              isPassword: true,
              isObscure: _obscurePass,
              onToggle: () => setState(() => _obscurePass = !_obscurePass),
              onChanged: (_) => setState(() {}),
            ),

            // ========== FIELD UMUM: KONFIRMASI PASSWORD ==========
            const SizedBox(height: 16),
            _buildLabel("Konfirmasi Password"),
            _buildFigmaTextField(
              _confirmController,
              "Min. 8 karakter",
              Icons.lock_outline,
              isPassword: true,
              isObscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),

            // ========== PASSWORD STRENGTH ==========
            const SizedBox(height: 16),
            _buildPasswordStrengthBar(strength),
            const SizedBox(height: 16),
            _buildPasswordChecklist(password),

            const SizedBox(height: 40),

            // ========== TOMBOL LANJUTKAN ==========
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2B0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Lanjutkan →",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                  children: [
                    const TextSpan(
                      text: "Dengan melanjutkan, Anda menyetujui ",
                    ),
                    TextSpan(
                      text: "Syarat & Ketentuan",
                      style: TextStyle(
                        color: const Color(0xFF8B2B0F).withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: " kami"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ========== FIELD KHUSUS CLIENT ==========
  List<Widget> _buildClientFields() {
    return [
      _buildLabel("Nama Lengkap"),
      _buildFigmaTextField(
        _nameController,
        "Masukkan nama lengkap",
        Icons.person_outline,
      ),
      const SizedBox(height: 16),
      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),
    ];
  }

  // ========== FIELD KHUSUS KONTRAKTOR ==========
  List<Widget> _buildKontraktorFields() {
    return [
      _buildLabel("Nama Perusahaan"),
      _buildFigmaTextField(
        _companyNameController,
        "Contoh: CV. Maju Bersama",
        Icons.business_outlined,
      ),

      const SizedBox(height: 16),
      _buildLabel("Identitas Penanggung Jawab (PIC)"),
      _buildFigmaTextField(
        _picNameController,
        "Masukan nama lengkap",
        Icons.person_outline,
      ),

      const SizedBox(height: 16),
      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),

      const SizedBox(height: 16),
      _buildLabel("NPWP PIC"),
      _buildFigmaTextField(
        _npwpController,
        "Masukan NPWP 15 digit",
        Icons.badge_outlined,
        keyboardType: TextInputType.number,
      ),

      const SizedBox(height: 16),
      _buildLabel("Foto NPWP (JPG, PNG)"),
      _buildNpwpUploadArea(),
    ];
  }

  // ========== FIELD KHUSUS ARSITEK ==========
  List<Widget> _buildArsitekFields() {
    return [
      _buildLabel("Nama Lengkap"),
      _buildFigmaTextField(
        _nameController,
        "Masukan nama lengkap",
        Icons.person_outline,
      ),
      const SizedBox(height: 16),
      
      _buildLabel("Nomor STRA"),
      _buildFigmaTextField(
        _straNumberController,
        "Masukan nomor STRA",
        Icons.badge_outlined,
      ),
      const SizedBox(height: 16),

      _buildLabel("Foto STRA (JPG, PNG)"),
      _buildStraUploadArea(),
      const SizedBox(height: 16),

      _buildLabel("Pengalaman Tahun"),
      _buildFigmaTextField(
        _experienceController,
        "Masukan waktu pengalaman",
        Icons.assignment_outlined,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),

      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),
    ];
  }

  // ========== WIDGET: Upload Area NPWP ==========
  Widget _buildNpwpUploadArea() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _npwpFileName != null
                ? const Color(0xFF8B2B0F)
                : Colors.grey.shade300,
            width: 1.5,
            // Dashed border effect via CustomPaint below
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: _npwpFile != null
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBE1),
                borderRadius: BorderRadius.circular(10),
                image: _npwpFile != null
                    ? DecorationImage(
                        image: FileImage(_npwpFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _npwpFile != null
                  ? null
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF8B2B0F),
                      size: 28,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              _npwpFileName != null ? "Foto terpilih" : "Tambah Foto",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _npwpFileName ?? "Tap untuk memilih file",
              style: TextStyle(
                color: _npwpFileName != null
                    ? const Color(0xFF8B2B0F)
                    : Colors.black45,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF8B2B0F).withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color: const Color(0xFF8B2B0F).withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Galeri",
                    style: TextStyle(
                      color: const Color(0xFF8B2B0F).withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET: Password Strength Bar ==========
  Widget _buildPasswordStrengthBar(int strength) {
    final label = _getStrengthLabel(strength);
    final color = _getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Kekuatan Password",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < strength ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ========== WIDGET: Password Checklist ==========
  Widget _buildPasswordChecklist(String password) {
    final checks = [
      {'label': 'Minimal 8 karakter', 'valid': password.length >= 8},
      {
        'label': 'Mengandung huruf besar',
        'valid': RegExp(r'[A-Z]').hasMatch(password),
      },
      {
        'label': 'Mengandung angka',
        'valid': RegExp(r'[0-9]').hasMatch(password),
      },
      {
        'label': 'Mengandung karakter khusus',
        'valid': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Syarat Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...checks.map((check) {
            final isValid = check['valid'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isValid
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: isValid
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    check['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? const Color(0xFF4CAF50) : Colors.black45,
                      fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========== WIDGET BUILDERS ==========
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFigmaTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF8B2B0F).withOpacity(0.8),
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B2B0F)),
        ),
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: const Color(0xFF8B2B0F).withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  "+62",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "812 3456 7890",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== WIDGET: Upload Area STRA ==========
  Widget _buildStraUploadArea() {
    return GestureDetector(
      onTap: _showStraImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _straFileName != null
                ? const Color(0xFF8B2B0F)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: _straFile != null
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBE1),
                borderRadius: BorderRadius.circular(10),
                image: _straFile != null
                    ? DecorationImage(
                        image: FileImage(_straFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _straFile == null
                  ? const Icon(Icons.badge_outlined, color: Color(0xFF8B2B0F))
                  : null,
            ),
            const SizedBox(height: 12),
            const Text(
              "Tambah Foto",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _straFileName ?? "Tap untuk memilih file",
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_straFileName == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EBE1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.photo_library, color: Color(0xFF8B2B0F), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Galeri / Kamera",
                      style: TextStyle(
                        color: Color(0xFF8B2B0F),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _pickStraPhoto(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      final ext = image.path.split('.').last.toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
        setState(() {
          _straFile = File(image.path);
          _straFileName = image.name;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format file harus JPG atau PNG!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStraImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickStraPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickStraPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ========== SCREEN: REGISTRASI BERHASIL ==========
class RegisterSuccessScreen extends StatefulWidget {
  final String role;
  const RegisterSuccessScreen({super.key, required this.role});

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // lebih singkat
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // lebih kalem, tidak terlalu mantul
    );

    // Mulai animasi sesaat setelah layar dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF), // Cream background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Badge Animasi
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B2B0F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              ),
              const SizedBox(height: 24), // sedikit lebih rapat

              const Text(
                "Registrasi Berhasil",
                style: TextStyle(
                  fontSize: 22, // lebih minimalis
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                "Silakan masuk ke akun Anda melalui\nhalaman login",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Tombol Masuk di bawah
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(role: widget.role),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Masuk",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B2B0F),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
