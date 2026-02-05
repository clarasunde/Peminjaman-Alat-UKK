import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Tambahkan provider
import '../auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    // 1. Validasi input
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Sandi tidak boleh kosong"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Gunakan Provider agar instance AuthService sama di seluruh aplikasi
    final authService = Provider.of<AuthService>(context, listen: false);

    final String? error = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        // 3. Ambil data user yang sudah tersimpan di AuthService
        final String? role = authService.userData?['role'];

        // 4. Logika Navigasi berdasarkan Role
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else if (role == 'petugas') {
          Navigator.pushReplacementNamed(context, '/petugas_home');
        } else if (role == 'peminjam') {
          Navigator.pushReplacementNamed(context, '/peminjam_home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Role tidak dikenali. Hubungi Admin."),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      } else {
        // Tampilkan error dari Supabase atau Trigger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... UI tetap sama seperti kodingan Anda karena sudah bagus ...
    // (Ganti bagian ElevatedButton onPressed untuk menggunakan _handleLogin)
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru Anda (Tetap sama)
            _buildHeader(), 
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Text("Welcome to MyBrantas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text("Temukan kebutuhan peminjaman perangkat digitalmu.", textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Sandi",
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4C90)),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("MASUK", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Pindahkan kode Stack header Anda ke sini agar build() lebih rapi
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF1E4C90),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(160), bottomRight: Radius.circular(160)),
          ),
        ),
        const Positioned(
          top: 80,
          child: Column(
            children: [
              CircleAvatar(radius: 50, child: Icon(Icons.devices_other, size: 60)),
              SizedBox(height: 10),
              Text("MY BRANTAS ID", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
      ],
    );
  }
}