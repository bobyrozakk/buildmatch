import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../forgot_password_screen.dart';
import '../role_screen.dart';

class LoginForm extends StatefulWidget {
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.isLoading,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    context.read<AuthCubit>().login(
      email: email,
      password: password,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Selamat Datang Kembali",
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
        const SizedBox(height: 40),
        
        // FORM EMAIL
        const Text(
          "Email",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _emailController,
          hintText: "contoh@gmail.com",
          prefixIcon: Icons.email_rounded,
        ),
        const SizedBox(height: 20),
        
        // FORM PASSWORD
        const Text(
          "Password",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _passwordController,
          hintText: "Masukkan password",
          prefixIcon: Icons.lock_rounded,
          isPassword: true,
          obscureText: _obscureText,
          onToggleObscure: () => setState(() => _obscureText = !_obscureText),
        ),
        const SizedBox(height: 12),
        
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: Text(
              "Lupa Password?",
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        
        // BUTTON MASUK
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Masuk",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 30),
        
        // DIVIDER GOOGLE
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "atau masuk dengan",
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 24),
        
        // BUTTON GOOGLE
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<AuthCubit>().loginWithGoogle();
            },
            icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: Colors.red),
            label: const Text(
              "Google",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
        
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RoleScreen()),
            ),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  TextSpan(text: "Belum punya akun? "),
                  TextSpan(
                    text: "Daftar Sekarang",
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black38, fontSize: 11),
              children: [
                const TextSpan(text: "Dengan masuk, Anda menyetujui "),
                TextSpan(
                  text: "Syarat & Ketentuan",
                  style: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: " kami"),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
