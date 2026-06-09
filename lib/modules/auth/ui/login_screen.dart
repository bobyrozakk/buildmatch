import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/buildmatch_appbar.dart';
import '../../../../ui/shared/screens/main_nav.dart';
import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';
import 'widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const BuildMatchAppBar(),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            String userFriendlyMessage = 'Email atau password salah.';
            final lowerError = state.message.toLowerCase();
            if (lowerError.contains('email not confirmed')) {
              userFriendlyMessage = 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda (termasuk folder spam) untuk memverifikasi akun.';
            } else if (lowerError.contains('invalid login credentials')) {
              userFriendlyMessage = 'Email atau password salah.';
            } else {
              userFriendlyMessage = state.message;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userFriendlyMessage),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: LoginForm(isLoading: state is AuthLoading),
          );
        },
      ),
    );
  }
}