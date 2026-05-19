import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT TAB KLIEN ---
import '../../client/tabs/beranda_tab.dart';
import '../../client/tabs/progress_tab.dart'; 
import '../../client/tabs/contractor_tab.dart';
import '../../client/tabs/profile_tab.dart'; 

// --- IMPORT TAB KONTRAKTOR ---s
import '../../kontraktor/tabs/kontraktor_home_tab.dart';
import '../../kontraktor/tabs/kontraktor_proyek_tab.dart';
import '../../kontraktor/tabs/kontraktor_progress_tab.dart';
import '../../kontraktor/tabs/kontraktor_profile_tab.dart'; 

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. CEK ROLE USER YANG LAGI LOGIN
    final user = Supabase.instance.client.auth.currentUser;
    // Ambil role dari metadata, default ke 'client' kalau kosong
    final role = user?.userMetadata?['role'] ?? 'client'; 

    // Cek apakah user ini vendor/kontraktor
    final isVendor = role == 'vendor' || role == 'kontraktor';

    // 2. SETUP DAFTAR HALAMAN (TABS)
    final List<Widget> clientTabs = [
      const BerandaTab(),
      const ContractorTab(),
      const Center(child: Text('Konsultasi Klien')), // Placeholder sementara
      const ProgressTab(), 
      const ProfileTab(), 
    ];

    final List<Widget> vendorTabs = [
      KontraktorHomeTab(
        onSwitchTab: (i) => setState(() => _currentIndex = i),
      ),
      const KontraktorProyekTab(),
      const KontraktorProgressTab(),
      const KontraktorProfileTab(),
    ];

    // 3. SETUP MENU BAWAH (NAV BAR)
    final List<NavigationDestination> clientDestinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.engineering_outlined), label: 'Kontraktor'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Konsultasi'),
      NavigationDestination(icon: Icon(Icons.timeline), label: 'Progress'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];

    final List<NavigationDestination> vendorDestinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.work_outline), label: 'Proyek'),
      NavigationDestination(icon: Icon(Icons.trending_up), label: 'Progress'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];

    // 4. LOGIKA PENENTUAN UI
    final activeTabs = isVendor ? vendorTabs : clientTabs;
    final activeDestinations = isVendor ? vendorDestinations : clientDestinations;

    return Scaffold(
      body: activeTabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: activeDestinations,
      ),
    );
  }
}