import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/buildmatch_appbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_new_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email terlebih dahulu.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link reset password telah dikirim ke email Anda.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateNewPasswordScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim email: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
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
          "Lupa Password",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Ilustrasi Kunci
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardCreamLight,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.key_rounded, size: 60, color: AppColors.primary),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Reset Password Anda",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "Masukkan email yang terdaftar. Kami akan\nmengirimkan link untuk membuat password\nbaru.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Email Input
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Email Terdaftar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "contoh@email.com",
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                const Text(
                  "Pastikan email aktif dan dapat diakses",
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardCreamMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Link akan dikirim ke email Anda",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.4),
                            children: [
                              TextSpan(text: "Link reset password berlaku selama "),
                              TextSpan(text: "15 menit", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              TextSpan(text: ". Periksa folder spam jika tidak ditemukan."),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _sendResetLink,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Kirim Link Reset",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                  children: [
                    TextSpan(text: "Ingat password? "),
                    TextSpan(text: "Masuk", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
