import 'package:flutter/material.dart';
import '../../../../modules/auth/ui/login_screen.dart';
import 'widgets/onboarding_slider.dart';
import 'widgets/onboarding_bottom_card.dart';
import 'widgets/onboarding_skip_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLoginScreen();
    }
  }

  void _goToLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "Temukan Kontraktor\nTerpercaya";
      case 1:
        return "Ajukan Proyek\ndengan Mudah";
      case 2:
        return "Pantau Progres\nPembangunan";
      default:
        return "";
    }
  }

  String _getDescription(int index) {
    switch (index) {
      case 0:
        return "Cari dan bandingkan kontraktor & arsitek terverifikasi sesuai kebutuhan proyek Anda";
      case 1:
        return "Buat deskripsi proyek, tentukan anggaran, dan terima penawaran dari beberapa kontraktor";
      case 2:
        return "Monitoring proyek secara real-time melalui laporan foto dan milestone dari kontraktor";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E9DF),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingSkipButton(onSkip: _goToLoginScreen),
            Expanded(
              child: OnboardingSlider(
                pageController: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
            ),
            OnboardingBottomCard(
              currentPage: _currentPage,
              title: _getTitle(_currentPage),
              description: _getDescription(_currentPage),
              onNext: _nextPage,
            ),
          ],
        ),
      ),
    );
  }
}
