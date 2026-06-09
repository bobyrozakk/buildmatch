import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/providers/project_provider.dart';
import 'data/providers/vendor_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/architect_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'modules/client/logic/project/project_cubit.dart';
import 'modules/client/logic/vendor/vendor_cubit.dart';
import 'modules/client/logic/architect/architect_cubit.dart';
import 'modules/client/logic/chat/chat_cubit.dart';
import 'modules/auth/logic/auth_cubit.dart';

// --- IMPORT SCREENS ---
import 'modules/startup/ui/splash/splash_screen.dart';

// --- IMPORT CONSTANTS ---
import 'core/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);

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
    MultiBlocProvider(
      providers: [
        BlocProvider<ProjectCubit>(create: (_) => ProjectCubit()),
        BlocProvider<VendorCubit>(create: (_) => VendorCubit()),
        BlocProvider<ArchitectCubit>(create: (_) => ArchitectCubit()),
        BlocProvider<ChatCubit>(create: (_) => ChatCubit()),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectProvider()),
          ChangeNotifierProvider(create: (_) => VendorProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => ArchitectProvider()),
        ],
        child: const BuildMatchApp(),
      ),
    ),
  );
}

class BuildMatchApp extends StatelessWidget {
  const BuildMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const SplashScreen(),
    );
  }
}