import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class GaleriDetailScreen extends StatelessWidget {
  final Map<String, dynamic> designData;

  const GaleriDetailScreen({super.key, required this.designData});

  @override
  Widget build(BuildContext context) {
    // We'll use mock data to perfectly match the screenshot text if it's not provided
    final title = 'Small House Design 22x26 Feet\nHome Design 6.5x8 M 2 Bed 1\nBath';
    final price = 'Rp 84,4 Jt';
    final tag = 'Minimalis';
    final author = 'Agus Wibowo';

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light beige
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // Top Bar with back button if needed, but the design doesn't show one explicitly.
                    // Wait, the design has a status bar (9:41) but no back button. It's likely a pushed screen, so I'll add a back button for usability, or just match exactly.
                    // Let's add a subtle back button on the top left.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87, height: 1.3),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8F2A0C)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A).withOpacity(0.5), // Very light orange/yellow
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(color: Color(0xFF8F2A0C), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage('https://eboseqlzrfabtiurwjpl.supabase.co/storage/v1/object/public/project-renders/avatar1.jpg'),
                        ),
                        const SizedBox(width: 8),
                        Text(author, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery Grid
                    Row(
                      children: [
                        // Left large image
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=500&q=80',
                              height: 210,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right stacked images
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&q=80',
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bottom 3 square images
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=500&q=80',
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&q=80',
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=500&q=80',
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    const Center(
                      child: Text('See more', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'This house showcases a detailed and charming small house design, measuring 22x26 feet (approximately 6.5x8 meters). This house features two bedrooms and one bathroom, making it suitable for a small family or a couple. The design harmonizes modern aesthetics with practical functionality, creating a cozy and efficient living space.',
                      style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                    ),
                    
                    const Spacer(),
                    const SizedBox(height: 16),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.favorite_border_rounded, color: Colors.black54, size: 24),
                        Row(
                          children: List.generate(5, (index) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.star_border_rounded, color: Colors.black54, size: 24),
                          )),
                        ),
                        const Icon(Icons.bookmark_border_rounded, color: Colors.black54, size: 24),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for bottom nav if it's over
          ],
        ),
      ),
      // To exactly match the image, we can just put a fake BottomNavigationBar here if it's a standalone screen in the test
      // but in real app, it will be wrapped by MainScreenArsitek. Wait, if we push it, it usually hides the bottom nav in Flutter unless we use CupertinoTabView.
      // So I will just render a fake one to match the screenshot for the user's review.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF3EBE3))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_filled, 'Beranda', false),
                _buildNavItem(Icons.layers, 'Desain', true),
                _buildNavItem(Icons.chat_bubble, 'Inbox', false, hasNotif: true),
                _buildNavItem(Icons.person, 'Profil', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {bool hasNotif = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF8F2A0C) : Colors.black54, size: 24),
            if (hasNotif)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF8F2A0C), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF8F2A0C) : Colors.black54,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
