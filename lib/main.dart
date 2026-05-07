import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// --- IMPORT PROVIDERS ---
import 'data/providers/project_provider.dart';
import 'data/providers/auth_provider.dart';

// --- IMPORT SCREENS ---
import 'ui/shared/screens/main_nav.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eboseqlzrfabtiurwjpl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVib3NlcWx6cmZhYnRpdXJ3anBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2ODMyOTUsImV4cCI6MjA5MjI1OTI5NX0.gUiVQ7RZAmLRlUFJ71LldgYOGmxU5VTdZqSI87jjLxo',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: const BuildMatchApp(),
    ),
  );
}

class BuildMatchApp extends StatelessWidget {
  const BuildMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BuildMatch',
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF7F4EF), // Disesuaikan dengan warna cream Figma
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B2B0F), // Disesuaikan dengan warna terakota Figma
            ),
            useMaterial3: true,
            fontFamily: 'Inter', // Opsional: Tambahin font Inter atau Roboto biar makin mirip Figma
          ),
          
          // LOGIC AUTH: Cek user udah login apa belum
          // Kalau belum login, lempar ke RoleScreen (Pilih Peran)
          home: auth.currentUser != null
              ? const MainNavScreen()
              : const OnboardingScreen(), 
        );
      },
    );
  }
}