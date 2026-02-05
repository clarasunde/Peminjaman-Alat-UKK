import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Import Service dan Screen yang telah kita perbaiki
import 'auth/auth_service.dart';
import 'auth/login.dart';
import 'admin.dart'; // File yang berisi daftar alat tadi

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Supabase
  // Ganti 'MASUKKAN_ANON_KEY_ASLI' dengan Key dari Dashboard Supabase Anda
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
        // Konsistensi font atau gaya bisa ditambahkan di sini
      ),
      
      // Menggunakan rute awal ke halaman Login
      initialRoute: '/',
      
      routes: {
        // Rute Login
        '/': (context) => const LoginScreen(),
        
        // Rute Admin (Halaman Dashboard Alat yang kita buat)
        '/admin_home': (context) => const AdminDashboard(),
        
        // Rute Petugas (Silakan ganti dengan class asli jika sudah ada)
        '/petugas_home': (context) => const PetugasDashboard(),
        
        // Rute Peminjam (Silakan ganti dengan class asli jika sudah ada)
        '/peminjam_home': (context) => const PeminjamDashboard(),
      },
    );
  }
}

// --- Placeholder untuk halaman yang belum dibuat agar tidak error ---

class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Petugas"), backgroundColor: Colors.orange),
      body: const Center(child: Text("Halaman khusus Petugas untuk Validasi Peminjaman")),
    );
  }
}

class PeminjamDashboard extends StatelessWidget {
  const PeminjamDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Peminjam"), backgroundColor: Colors.green),
      body: const Center(child: Text("Halaman khusus Peminjam untuk Request Alat")),
    );
  }
}