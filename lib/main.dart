import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'auth/login.dart';
import 'admin/admin_home.dart'; // Memanggil file dengan Navbar

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bfmadvkubnpgarzchvqh.supabase.co',
    anonKey: 'sb_publishable_dXv0dvhBX5796bN7eOvuaw_Dgq5dpIQ', 
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Brantas ID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4C90)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/admin_home': (context) => const AdminHomeScreen(), 
        '/petugas_home': (context) => const PetugasDashboard(),
        '/peminjam_home': (context) => const PeminjamDashboard(),
      },
    );
  }
}

// --- BAGIAN INI WAJIB ADA AGAR TIDAK ERROR MERAH ---

class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Petugas"), backgroundColor: Colors.blue),
      body: const Center(child: Text("Halaman Petugas")),
    );
  }
}

class PeminjamDashboard extends StatelessWidget {
  const PeminjamDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Peminjam"), backgroundColor: Colors.green),
      body: const Center(child: Text("Halaman Peminjam")),
    );
  }
}