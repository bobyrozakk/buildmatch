import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/auth_cubit.dart';

class _NibInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 13 ? digits.substring(0, 13) : digits;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 4 || i == 8 || i == 12) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final String role;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.role,
    required this.isLoading,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
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
  String? _npwpFileName;
  File? _npwpFile;

  // Controller khusus NIB
  final _nibController = TextEditingController();
  String? _nibFileName;
  File? _nibFile;

  // Controller khusus Arsitek
  final _straNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _straFileName;
  File? _straFile;

  bool get _isKontraktor => widget.role.toLowerCase() == 'kontraktor';
  bool get _isArsitek => widget.role.toLowerCase() == 'arsitek';

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _companyNameController.dispose();
    _picNameController.dispose();
    _npwpController.dispose();
    _nibController.dispose();
    _straNumberController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

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
      case 0: return '';
      case 1: return 'Lemah';
      case 2: return 'Sedang';
      case 3: return 'Kuat';
      case 4: return 'Sangat Kuat';
      default: return '';
    }
  }

  Color _getStrengthColor(int score) {
    switch (score) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return const Color(0xFF4CAF50);
      case 4: return const Color(0xFF2E7D32);
      default: return Colors.grey.shade300;
    }
  }

  void _submit() {
    final email = _emailController.text.trim();
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

    String? nibDigits;
    if (_isKontraktor) {
      nibDigits = _nibController.text.replaceAll(' ', '');
      if (nibDigits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIB wajib diisi!'), backgroundColor: Colors.red));
        return;
      }
      if (nibDigits.length != 13) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIB harus tepat 13 digit angka!'), backgroundColor: Colors.red));
        return;
      }
      if (!RegExp(r'^[0-9]{13}$').hasMatch(nibDigits)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIB hanya boleh berisi angka!'), backgroundColor: Colors.red));
        return;
      }
    }

    String name = _nameController.text.trim();
    if (_isKontraktor) name = _picNameController.text.trim();

    context.read<AuthCubit>().register(
      email: email,
      password: _passwordController.text,
      name: name,
      phone: "+62${_phoneController.text.trim()}",
      role: widget.role.toLowerCase(),
      companyName: _isKontraktor ? _companyNameController.text.trim() : null,
      picName: _isKontraktor ? _picNameController.text.trim() : null,
      npwp: _isKontraktor ? _npwpController.text.trim() : null,
      npwpFile: _isKontraktor ? _npwpFile : null,
      nib: _isKontraktor ? nibDigits : null,
      nibFile: _isKontraktor ? _nibFile : null,
      straNumber: _isArsitek ? _straNumberController.text.trim() : null,
      experienceYears: _isArsitek ? _experienceController.text.trim() : null,
      straFile: _isArsitek ? _straFile : null,
    );
  }

  Future<void> _pickNpwpPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        final extension = image.name.split('.').last.toLowerCase();
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          setState(() {
            _npwpFile = File(image.path);
            _npwpFileName = image.name;
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hanya format JPG dan PNG yang didukung!'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Error picking NPWP image: $e");
    }
  }

  void _showNpwpImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Sumber Foto NPWP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTypeTile(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera',
                onTap: () { Navigator.pop(context); _pickNpwpPhoto(ImageSource.camera); },
              ),
              ListTypeTile(
                icon: Icons.photo_library_outlined,
                title: 'Galeri',
                onTap: () { Navigator.pop(context); _pickNpwpPhoto(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickNibPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        final extension = image.name.split('.').last.toLowerCase();
        if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
          setState(() {
            _nibFile = File(image.path);
            _nibFileName = image.name;
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hanya format JPG dan PNG yang didukung!'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Error picking NIB image: $e");
    }
  }

  void _showNibImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Sumber Foto NIB", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTypeTile(
                icon: Icons.camera_alt_outlined,
                title: 'Kamera',
                onTap: () { Navigator.pop(context); _pickNibPhoto(ImageSource.camera); },
              ),
              ListTypeTile(
                icon: Icons.photo_library_outlined,
                title: 'Galeri',
                onTap: () { Navigator.pop(context); _pickNibPhoto(ImageSource.gallery); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStraPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Format file harus JPG atau PNG!'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Error picking STRA image: $e");
    }
  }

  void _showStraImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTypeTile(
              icon: Icons.camera_alt,
              title: 'Kamera',
              onTap: () { Navigator.pop(context); _pickStraPhoto(ImageSource.camera); },
            ),
            ListTypeTile(
              icon: Icons.photo_library,
              title: 'Galeri',
              onTap: () { Navigator.pop(context); _pickStraPhoto(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _getPasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Buat Akun Baru", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        const Text("Masuk ke akun BuildMatch Anda", style: TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 30),

        if (_isKontraktor)
          ..._buildKontraktorFields()
        else if (_isArsitek)
          ..._buildArsitekFields()
        else
          ..._buildClientFields(),

        const SizedBox(height: 16),
        _buildLabel("Email"),
        _buildFigmaTextField(_emailController, "contoh@gmail.com", Icons.email_outlined),

        const SizedBox(height: 16),
        _buildLabel("Password"),
        _buildFigmaTextField(
          _passwordController, "Min. 8 karakter", Icons.lock_outline,
          isPassword: true, isObscure: _obscurePass,
          onToggle: () => setState(() => _obscurePass = !_obscurePass),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),
        _buildLabel("Konfirmasi Password"),
        _buildFigmaTextField(
          _confirmController, "Min. 8 karakter", Icons.lock_outline,
          isPassword: true, isObscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 16),
        _buildPasswordStrengthBar(strength),
        const SizedBox(height: 16),
        _buildPasswordChecklist(password),
        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2B0F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text("Lanjutkan →", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.black38, fontSize: 11),
              children: [
                const TextSpan(text: "Dengan melanjutkan, Anda menyetujui "),
                TextSpan(text: "Syarat & Ketentuan", style: TextStyle(color: const Color(0xFF8B2B0F).withOpacity(0.8), fontWeight: FontWeight.bold)),
                const TextSpan(text: " kami"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _buildClientFields() {
    return [
      _buildLabel("Nama Lengkap"),
      _buildFigmaTextField(_nameController, "Masukkan nama lengkap", Icons.person_outline),
      const SizedBox(height: 16),
      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),
    ];
  }

  List<Widget> _buildKontraktorFields() {
    return [
      _buildLabel("Nama Perusahaan"),
      _buildFigmaTextField(_companyNameController, "Contoh: CV. Maju Bersama", Icons.business_outlined),
      const SizedBox(height: 16),
      _buildLabel("Identitas Penanggung Jawab (PIC)"),
      _buildFigmaTextField(_picNameController, "Masukan nama lengkap", Icons.person_outline),
      const SizedBox(height: 16),
      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),
      const SizedBox(height: 16),
      _buildLabel("NPWP PIC"),
      _buildFigmaTextField(_npwpController, "Masukan NPWP 15 digit", Icons.badge_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      _buildLabel("Foto NPWP (JPG, PNG)"),
      _buildNpwpUploadArea(),
      const SizedBox(height: 16),
      _buildLabel("NIB (Nomor Induk Berusaha)"),
      _buildNibTextField(),
      const SizedBox(height: 4),
      const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Text(
          "13 digit angka • Format otomatis: XXXX XXXX XXXX X",
          style: TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ),
      const SizedBox(height: 16),
      _buildLabel("Foto Bukti NIB (JPG, PNG)"),
      _buildNibUploadArea(),
    ];
  }

  List<Widget> _buildArsitekFields() {
    return [
      _buildLabel("Nama Lengkap"),
      _buildFigmaTextField(_nameController, "Masukan nama lengkap", Icons.person_outline),
      const SizedBox(height: 16),
      _buildLabel("Nomor STRA"),
      _buildFigmaTextField(_straNumberController, "Masukan nomor STRA", Icons.badge_outlined),
      const SizedBox(height: 16),
      _buildLabel("Foto STRA (JPG, PNG)"),
      _buildStraUploadArea(),
      const SizedBox(height: 16),
      _buildLabel("Pengalaman Tahun"),
      _buildFigmaTextField(_experienceController, "Masukan waktu pengalaman", Icons.assignment_outlined, keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      _buildLabel("No. Telepon"),
      _buildPhoneField(_phoneController),
    ];
  }

  Widget _buildNpwpUploadArea() {
    return GestureDetector(
      onTap: _showNpwpImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _npwpFileName != null ? const Color(0xFF8B2B0F) : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: _npwpFile != null ? EdgeInsets.zero : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBE1),
                borderRadius: BorderRadius.circular(10),
                image: _npwpFile != null ? DecorationImage(image: FileImage(_npwpFile!), fit: BoxFit.cover) : null,
              ),
              child: _npwpFile != null ? null : const Icon(Icons.camera_alt_rounded, color: Color(0xFF8B2B0F), size: 28),
            ),
            const SizedBox(height: 12),
            Text(_npwpFileName != null ? "Foto terpilih" : "Tambah Foto", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _npwpFileName ?? "Tap untuk memilih file",
              style: TextStyle(color: _npwpFileName != null ? const Color(0xFF8B2B0F) : Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B2B0F).withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 14, color: const Color(0xFF8B2B0F).withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text("Galeri", style: TextStyle(color: const Color(0xFF8B2B0F).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNibTextField() {
    return TextFormField(
      controller: _nibController,
      keyboardType: TextInputType.number,
      inputFormatters: [_NibInputFormatter()],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "XXXX XXXX XXXX X",
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(Icons.article_outlined, color: const Color(0xFF8B2B0F).withOpacity(0.8), size: 20),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${_nibController.text.replaceAll(' ', '').length}/13",
                style: TextStyle(
                  fontSize: 11,
                  color: _nibController.text.replaceAll(' ', '').length == 13
                      ? const Color(0xFF4CAF50)
                      : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B2B0F))),
      ),
    );
  }

  Widget _buildNibUploadArea() {
    return GestureDetector(
      onTap: _showNibImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _nibFileName != null ? const Color(0xFF8B2B0F) : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: _nibFile != null ? EdgeInsets.zero : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBE1),
                borderRadius: BorderRadius.circular(10),
                image: _nibFile != null ? DecorationImage(image: FileImage(_nibFile!), fit: BoxFit.cover) : null,
              ),
              child: _nibFile != null ? null : const Icon(Icons.article_outlined, color: Color(0xFF8B2B0F), size: 28),
            ),
            const SizedBox(height: 12),
            Text(_nibFileName != null ? "Foto terpilih" : "Tambah Foto NIB", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _nibFileName ?? "Tap untuk memilih file",
              style: TextStyle(color: _nibFileName != null ? const Color(0xFF8B2B0F) : Colors.black45, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8B2B0F).withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 14, color: const Color(0xFF8B2B0F).withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text("Galeri", style: TextStyle(color: const Color(0xFF8B2B0F).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(int strength) {
    final label = _getStrengthLabel(strength);
    final color = _getStrengthColor(strength);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Kekuatan Password", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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

  Widget _buildPasswordChecklist(String password) {
    final checks = [
      {'label': 'Minimal 8 karakter', 'valid': password.length >= 8},
      {'label': 'Mengandung huruf besar', 'valid': RegExp(r'[A-Z]').hasMatch(password)},
      {'label': 'Mengandung angka', 'valid': RegExp(r'[0-9]').hasMatch(password)},
      {'label': 'Mengandung karakter khusus', 'valid': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)},
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
          const Text("Syarat Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          ...checks.map((check) {
            final isValid = check['valid'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(isValid ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: isValid ? const Color(0xFF4CAF50) : Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Text(check['label'] as String, style: TextStyle(fontSize: 12, color: isValid ? const Color(0xFF4CAF50) : Colors.black45, fontWeight: isValid ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
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
        prefixIcon: Icon(icon, color: const Color(0xFF8B2B0F).withOpacity(0.8), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38, size: 20),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B2B0F))),
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              children: [
                Icon(Icons.phone_outlined, color: const Color(0xFF8B2B0F).withOpacity(0.8), size: 18),
                const SizedBox(width: 8),
                const Text("+62", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: "812 3456 7890", hintStyle: TextStyle(color: Colors.black38, fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStraUploadArea() {
    return GestureDetector(
      onTap: _showStraImageSourceDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _straFileName != null ? const Color(0xFF8B2B0F) : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: _straFile != null ? EdgeInsets.zero : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBE1),
                borderRadius: BorderRadius.circular(10),
                image: _straFile != null ? DecorationImage(image: FileImage(_straFile!), fit: BoxFit.cover) : null,
              ),
              child: _straFile == null ? const Icon(Icons.badge_outlined, color: Color(0xFF8B2B0F)) : null,
            ),
            const SizedBox(height: 12),
            const Text("Tambah Foto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(_straFileName ?? "Tap untuk memilih file", style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_straFileName == null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF3EBE1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.photo_library, color: Color(0xFF8B2B0F), size: 14),
                    SizedBox(width: 4),
                    Text("Galeri / Kamera", style: TextStyle(color: Color(0xFF8B2B0F), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ListTypeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ListTypeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
