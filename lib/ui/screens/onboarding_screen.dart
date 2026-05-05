import 'package:flutter/material.dart';
import 'role_screen.dart';

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
      _goToRoleScreen();
    }
  }

  void _goToRoleScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E9DF), // Warna background cream dasar
      body: SafeArea(
        child: Column(
          children: [
            // Header (Lewati)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _goToRoleScreen,
                    child: const Text(
                      "Lewati",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView untuk Ilustrasi
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide1Illustration(),
                  _buildSlide2Illustration(),
                  _buildSlide3Illustration(),
                ],
              ),
            ),

            // Bottom Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24.0),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF8B2B0F)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Teks Judul
                  Text(
                    _getTitle(_currentPage),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teks Deskripsi
                  Text(
                    _getDescription(_currentPage),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Selanjutnya / Mulai
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == 2
                            ? const Color(0xFF8B2B0F)
                            : const Color(0xFF8B2B0F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2
                                ? "Mulai Sekarang"
                                : "Selanjutnya",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 2
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
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

  // ==========================================
  // ILUSTRASI MOCKUP DENGAN FLUTTER WIDGETS
  // ==========================================

  Widget _buildSlide1Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Abstract Circles
        Positioned(
          top: 20,
          left: 40,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8CDB6).withOpacity(0.6),
          ),
        ),
        Positioned(
          bottom: 60,
          right: 30,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8CDB6).withOpacity(0.8),
          ),
        ),
        // Tengah (Background shadow shape)
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8CDB6).withOpacity(0.4),
          ),
        ),

        // Mockup HP (Kontraktor List)
        Container(
          width: 180,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: Column(
            children: [
              // Header mockup
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B2B0F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Kontraktor",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // List items
              _buildMockListCard(),
              _buildMockListCard(active: true),
              _buildMockListCard(),
              const Spacer(),
              // Bottom search bar mock
              Container(
                margin: const EdgeInsets.all(12),
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),

        // Verified Badge
        Positioned(
          top: 60,
          right: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2B0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  "Verified",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Rating Badge
        Positioned(
          bottom: 90,
          left: 70,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 12),
                SizedBox(width: 4),
                Text(
                  "4.9",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockListCard({bool active = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF8B2B0F) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF8B2B0F).withOpacity(0.1),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE8CDB6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.business,
              color: Color(0xFF8B2B0F),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 6, width: 50, color: Colors.black87),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF8B2B0F) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Abstract Circles
        Positioned(
          top: 40,
          left: 50,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE8CDB6).withOpacity(0.8),
          ),
        ),
        // Tengah (Background shadow shape)
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8CDB6).withOpacity(0.4),
          ),
        ),

        // Background mock cards (berbayang di belakang)
        Positioned(
          left: 60,
          child: Container(
            width: 140,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFC95E36).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          right: 60,
          child: Container(
            width: 140,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFE8CDB6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Main Proposal Card
        Container(
          width: 200,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B2B0F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "PROPOSAL PROYEK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8CDB6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Color(0xFF8B2B0F),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 8,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 6,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      width: 120,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      width: 80,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniIcon(Icons.home_work),
                        _buildMiniIcon(Icons.bar_chart),
                        _buildMiniIcon(Icons.handshake),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3 Offer Badge
        Positioned(
          top: 60,
          right: 70,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF8B2B0F),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "3",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  "Offer",
                  style: TextStyle(color: Colors.white, fontSize: 8),
                ),
              ],
            ),
          ),
        ),

        // Anggaran Badge
        Positioned(
          bottom: 30,
          left: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.monetization_on, color: Color(0xFFC95E36), size: 14),
                SizedBox(width: 4),
                Text(
                  "Anggaran",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8CDB6).withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: const Color(0xFF8B2B0F), size: 14),
    );
  }

  Widget _buildSlide3Illustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Abstract Circles
        Positioned(
          top: 20,
          left: 40,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8CDB6).withOpacity(0.8),
          ),
        ),
        Positioned(
          bottom: 70,
          right: 40,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE8CDB6).withOpacity(0.4),
          ),
        ),

        // Progress Card Mockup
        Container(
          width: 220,
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 8, width: 80, color: Colors.black87),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8CDB6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Color(0xFF8B2B0F),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Progres Keseluruhan",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "72%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC95E36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2B0F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Checklist items
              _buildProgressCheck(active: true),
              _buildProgressCheck(active: true),
              _buildProgressCheck(active: false, inProgress: true),
            ],
          ),
        ),

        // Foto Laporan Badge
        Positioned(
          top: 100,
          right: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2B0F),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Foto Laporan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "12 foto baru",
                      style: TextStyle(color: Colors.white70, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Update Milestone Badge
        Positioned(
          bottom: 50,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Color(0xFFC95E36),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Update Milestone",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Struktur selesai ✓",
                      style: TextStyle(color: Colors.black54, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCheck({bool active = false, bool inProgress = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF8B2B0F)
                  : (inProgress ? Colors.transparent : Colors.transparent),
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? const Color(0xFF8B2B0F)
                    : (inProgress
                          ? const Color(0xFFC95E36)
                          : Colors.grey.shade300),
                width: 2,
              ),
            ),
            child: active
                ? const Icon(Icons.check, color: Colors.white, size: 10)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? Colors.grey.shade300
                    : (inProgress
                          ? const Color(0xFFC95E36)
                          : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            active
                ? Icons.check_circle
                : (inProgress
                      ? Icons.access_time_filled
                      : Icons.circle_outlined),
            color: active
                ? Colors.green
                : (inProgress ? const Color(0xFFC95E36) : Colors.grey.shade300),
            size: 14,
          ),
        ],
      ),
    );
  }
}
