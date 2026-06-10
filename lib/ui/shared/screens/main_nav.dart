import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT TAB KLIEN ---
import '../../../modules/client/ui/tabs/beranda/beranda_tab.dart';
import '../../../modules/client/ui/tabs/progress/progress_tab.dart'; 
import '../../../modules/client/ui/tabs/mitra/mitra_tab.dart';
import '../../../modules/client/ui/tabs/consultasi/consultasi_tab.dart';
import '../../../modules/client/ui/tabs/profile/profile_tab.dart'; 

// --- IMPORT TAB KONTRAKTOR ---
import '../../../modules/kontraktor/ui/tabs/kontraktor_home_tab.dart';
import '../../../modules/kontraktor/ui/tabs/kontraktor_proyek_tab.dart';
import '../../../modules/kontraktor/ui/tabs/kontraktor_progress_tab.dart';
import '../../../modules/kontraktor/ui/tabs/kontraktor_profile_tab.dart'; 


// --- IMPORT TAB ARSITEK ---
import '../../arsitek/tabs/arsitek_home_tab.dart';
import '../../arsitek/tabs/arsitek_desain_tab.dart';
import '../../arsitek/tabs/arsitek_inbox_tab.dart';
import '../../arsitek/tabs/arsitek_profile_tab.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  int _mitraInitialTab = 0;

  void _handleSwitchTab(int index) {
    setState(() {
      if (index == 99) {
        _currentIndex = 1;      // Go to MitraTab (index 1)
        _mitraInitialTab = 1;   // Select Arsitek tab inside MitraTab
      } else {
        _currentIndex = index;
        _mitraInitialTab = 0;   // Reset to Contractor tab
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'client';
    debugPrint('=== DEBUG MainNav ===');
    debugPrint('User ID: ${user?.id}');
    debugPrint('userMetadata: ${user?.userMetadata}');
    debugPrint('Role terbaca: $role');
    debugPrint('====================');

    final isVendor = role == 'vendor' || role == 'kontraktor';
    final isArchitect = role == 'architect' || role == 'arsitek';

    // 2. SETUP DAFTAR HALAMAN (TABS)
    final List<Widget> clientTabs = [
      BerandaTab(
        onSwitchTab: _handleSwitchTab,
      ),
      MitraTab(
        key: UniqueKey(),
        initialTab: _mitraInitialTab,
      ),
      const ConsultasiTab(), // Konsultasi: Inbox + Arsitek dalam 1 tab
      ProgressTab(
        onSwitchTab: _handleSwitchTab,
      ),
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

    final List<Widget> architectTabs = [
      ArsitekHomeTab(
        onSwitchTab: (i) => setState(() => _currentIndex = i),
      ),
      const ArsitekDesainTab(),
      const ArsitekInboxTab(),
      const ArsitekProfileTab(),
    ];

    // 3. SETUP MENU BAWAH (NAV BAR)
    final List<NavigationDestination> clientDestinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Mitra'),
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

    final List<NavigationDestination> architectDestinations = const [
      NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
      NavigationDestination(icon: Icon(Icons.architecture_outlined), label: 'Desain'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
    ];

    // 4. LOGIKA PENENTUAN UI
    final activeTabs = isArchitect 
        ? architectTabs 
        : (isVendor ? vendorTabs : clientTabs);
    final activeDestinations = isArchitect 
        ? architectDestinations 
        : (isVendor ? vendorDestinations : clientDestinations);

    // Safety check: reset index if out of bounds for the current role
    final safeIndex = _currentIndex >= activeTabs.length ? 0 : _currentIndex;

    return Scaffold(
      body: activeTabs[safeIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: activeDestinations,
      ),
    );
  }
}