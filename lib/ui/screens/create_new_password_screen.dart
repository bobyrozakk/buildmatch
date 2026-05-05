import 'package:flutter/material.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSuccess = false;

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
    if (score == 0) return "";
    if (score <= 2) return "Lemah";
    if (score == 3) return "Sedang";
    return "Kuat";
  }

  Color _getStrengthColor(int score) {
    if (score == 0) return Colors.grey.shade300;
    if (score <= 2) return Colors.red;
    if (score == 3) return Colors.orange;
    return Colors.green;
  }

  Widget _buildPasswordChecklist(String password) {
    final checks = [
      {'label': 'Minimal 8 karakter', 'valid': password.length >= 8},
      {'label': 'Mengandung huruf besar', 'valid': RegExp(r'[A-Z]').hasMatch(password)},
      {'label': 'Mengandung angka', 'valid': RegExp(r'[0-9]').hasMatch(password)},
      {'label': 'Mengandung karakter khusus', 'valid': RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EBE1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Syarat Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          ...checks.map((check) {
            final isValid = check['valid'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_rounded : Icons.check_circle_rounded,
                    color: isValid ? Colors.green : Colors.grey.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    check['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isValid ? Colors.green : Colors.grey.shade500,
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

  void _saveNewPassword() {
    // Validasi dasar
    if (_getPasswordStrength(_passwordController.text) < 4 || 
        _passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan password memenuhi syarat dan cocok!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Tampilkan sukses
    setState(() {
      _isSuccess = true;
    });

    // Simulasi kembali ke login setelah sukses
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(_passwordController.text);
    final strengthColor = _getStrengthColor(strength);
    final strengthLabel = _getStrengthLabel(strength);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Buat Password Baru",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Password Baru",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Password baru harus berbeda dari password sebelumnya",
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),

            // Password Baru
            const Text("Password Baru", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: "••••••••",
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF8B2B0F), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black54, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B2B0F)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B2B0F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B2B0F), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Konfirmasi Password Baru
            const Text("Konfirmasi Password Baru", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: "Min. 8 karakter",
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.black38, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.black38, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
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
                  borderSide: const BorderSide(color: Color(0xFF8B2B0F), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Indikator Kekuatan
            Row(
              children: [
                const Text("Kekuatan Password", style: TextStyle(fontSize: 12, color: Colors.black54)),
                const Spacer(),
                Text(strengthLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor)),
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
                      color: index < strength ? strengthColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Checklist
            _buildPasswordChecklist(_passwordController.text),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveNewPassword,
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Simpan Password Baru",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2B0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Success Box (muncul jika isSuccess true)
            if (_isSuccess)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isSuccess ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // Hijau sesuai desain
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password berhasil diperbarui!",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Silakan masuk dengan password baru Anda",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        onPressed: () => setState(() => _isSuccess = false),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
