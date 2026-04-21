import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// --- IMPORT PROVIDERS ---
import 'data/providers/project_provider.dart';
import 'data/providers/auth_provider.dart'; // Ini yang ngilangin merah di AuthProvider & currentUser

// --- IMPORT SCREENS ---
import 'ui/screens/main_nav.dart';
import 'ui/screens/login_screen.dart'; // Ini yang ngilangin merah di LoginScreen

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
      // Panggil BuildMatchApp di sini biar strukturnya rapi
      child: const BuildMatchApp(),
    ),
  );
}

class BuildMatchApp extends StatelessWidget {
  const BuildMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer dipindah ke sini, ngebungkus MaterialApp
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BuildMatch',
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2B5C8F),
            ),
            useMaterial3: true,
          ),
          // LOGIC AUTH: Cek user udah login apa belum
          home: auth.currentUser != null
              ? const MainNavScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
