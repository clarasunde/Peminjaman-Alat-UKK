import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Services
import 'auth/auth_service.dart';

/// Screens
import 'auth/login.dart';
import 'admin/admin_home.dart';
import 'petugas/petugas.dart';
import 'peminjam/peminjam.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 WAJIB biar DateFormat('id_ID') tidak error
  await initializeDateFormatting('id_ID', null);

  /// 🔥 Supabase init
  await Supabase.initialize(
    url: 'https://bfmadvkubnpgarzchvqh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmbWFkdmt1Ym5wZ2FyemNodnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1ODU2ODcsImV4cCI6MjA4NDE2MTY4N30.qhkfUvAXyHk1w_w6w_sDB9jFb312KvrAYKG1cIXkW2s',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Brantas ID',

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E4C90),
          ),
        ),

        initialRoute: '/',

        routes: {
          '/': (_) => const LoginScreen(),
          '/admin_home': (_) => const AdminHomeScreen(),
          '/petugas_home': (_) => const PetugasPage(),
          '/peminjam_home': (_) => const PeminjamPage(),
        },
      ),
    );
  }
}
