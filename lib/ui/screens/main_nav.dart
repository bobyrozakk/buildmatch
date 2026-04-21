import 'package:flutter/material.dart';
import '../tabs/beranda_tab.dart';
import '../tabs/progress_tab.dart'; // Import tab progress

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const BerandaTab(),
    const Center(child: Text('List Kontraktor')),
    const Center(child: Text('Konsultasi')),
    const ProgressTab(), // Masukkan widget ProgressTab di sini
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.engineering_outlined), label: 'Kontraktor'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Konsultasi'),
          NavigationDestination(icon: Icon(Icons.timeline), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}