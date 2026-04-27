import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import 'main_nav.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  void _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok!'), backgroundColor: Colors.red));
      return;
    }

    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: "+62${_phoneController.text.trim()}",
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavScreen()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Register gagal.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF8B2B0F), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.architecture, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text("BuildMatch", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8B2B0F)),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text("Client", style: TextStyle(color: Color(0xFF8B2B0F), fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Buat Akun Baru", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text("Masuk ke akun BuildMatch Anda", style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 30),

            _buildLabel("Nama Lengkap"),
            _buildFigmaTextField(_nameController, "Masukkan nama lengkap", Icons.person_outline),
            
            const SizedBox(height: 16),
            _buildLabel("Email"),
            _buildFigmaTextField(_emailController, "contoh@email.com", Icons.email_outlined),

            const SizedBox(height: 16),
            _buildLabel("No. Telepon"),
            _buildPhoneField(_phoneController),

            const SizedBox(height: 16),
            _buildLabel("Password Baru"),
            _buildFigmaTextField(_passwordController, "Min. 8 karakter", Icons.lock_outline, isPassword: true, isObscure: _obscurePass, onToggle: () => setState(() => _obscurePass = !_obscurePass)),

            const SizedBox(height: 16),
            _buildLabel("Konfirmasi Password Baru"),
            _buildFigmaTextField(_confirmController, "Min. 8 karakter", Icons.lock_outline, isPassword: true, isObscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2B0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Lanjutkan ➔", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildFigmaTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, bool isObscure = false, VoidCallback? onToggle}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF8B2B0F).withOpacity(0.8), size: 20),
        suffixIcon: isPassword ? IconButton(icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38, size: 20), onPressed: onToggle) : null,
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
            child: Row(children: [Icon(Icons.phone_outlined, color: const Color(0xFF8B2B0F).withOpacity(0.8), size: 18), const SizedBox(width: 8), const Text("+62", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))]),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: "812 3456 7890", hintStyle: TextStyle(color: Colors.black38, fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
            ),
          )
        ],
      ),
    );
  }
}