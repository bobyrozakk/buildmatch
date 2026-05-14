import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// --- IMPORT PROVIDERS ---
import 'data/providers/project_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/vendor_provider.dart';

// --- IMPORT SCREENS ---
import 'ui/shared/screens/main_nav.dart';
import 'ui/screens/onboarding_screen.dart';

// --- IMPORT CONSTANTS ---
import 'core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Credentials dimuat dari --dart-define saat build/run.
  // Contoh: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx
  // Fallback values hanya untuk development — JANGAN push ke Git publik.
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eboseqlzrfabtiurwjpl.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVib3NlcWx6cmZhYnRpdXJ3anBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2ODMyOTUsImV4cCI6MjA5MjI1OTI5NX0.gUiVQ7RZAmLRlUFJ71LldgYOGmxU5VTdZqSI87jjLxo',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
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
            scaffoldBackgroundColor: AppColors.backgroundCream,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
          ),

          // Auth check: jika belum login → Onboarding, sudah login → MainNav
          home: auth.currentUser != null
              ? const MainNavScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}