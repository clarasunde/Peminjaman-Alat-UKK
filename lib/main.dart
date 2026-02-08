import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'auth/auth_service.dart';
import 'auth/login.dart';
import 'admin/admin_home.dart';

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
          '/petugas_home': (_) => const PetugasDashboard(),
          '/peminjam_home': (_) => const PeminjamDashboard(),
        },
      ),
    );
  }
}

class PetugasDashboard extends StatelessWidget {
  const PetugasDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Petugas")),
      body: const Center(child: Text("Halaman Petugas")),
    );
  }
}

class PeminjamDashboard extends StatelessWidget {
  const PeminjamDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Peminjam")),
      body: const Center(child: Text("Halaman Peminjam")),
    );
  }
}
