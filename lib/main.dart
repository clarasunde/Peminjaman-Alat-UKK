import 'package:flutter/material.dart';
import 'package:flutter_application_1/peminjam/peminjam.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Import Service dan Screen
import 'auth/auth_service.dart';
import 'auth/login.dart';
import 'admin/admin_home.dart';
import 'petugas/petugas.dart'; // Ini penting agar PetugasPage terbaca

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        title: 'My Brantas ID',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E4C90),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const LoginScreen(),
          '/admin_home': (_) => const AdminHomeScreen(),
          // DIUBAH: Sekarang mengarah ke PetugasPage di petugas.dart
          '/petugas_home': (_) => const PetugasPage(), 
          '/peminjam_home': (_) => const PeminjamPage(),
        },
      ),
    );
  }
}