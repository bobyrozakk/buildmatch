import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/glass_card.dart'; // Import IOSGlassCard
import '../../data/providers/auth_provider.dart';
import 'main_nav.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true; // Toggle antara Login dan Register

  void _submit() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isLoginMode) {
      success = await provider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nama wajib diisi!')));
        return;
      }
      success = await provider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      // Masuk ke halaman utama
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode
                ? 'Login Gagal. Cek email/password.'
                : 'Register Gagal. Coba lagi.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFFFF0F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.architecture_rounded,
                    size: 80,
                    color: Color(0xFFB53D1B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "BuildMatch",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB53D1B),
                    ),
                  ),
                  const Text(
                    "Wujudkan Proyek Impianmu",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  IOSGlassCard(
                    blur: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            _isLoginMode ? "Welcome Back" : "Create Account",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!_isLoginMode) ...[
                            _buildTextField(
                              _nameController,
                              "Nama Lengkap",
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField(
                            _emailController,
                            "Email",
                            Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _passwordController,
                            "Password",
                            Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB53D1B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      _isLoginMode ? "Login" : "Sign Up",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () =>
                                setState(() => _isLoginMode = !_isLoginMode),
                            child: Text(
                              _isLoginMode
                                  ? "Belum punya akun? Daftar"
                                  : "Sudah punya akun? Login",
                              style: const TextStyle(
                                color: Color(0xFFB53D1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
