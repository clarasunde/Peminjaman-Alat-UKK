import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  // =====================================
  // LOGIN FUNCTION (FIXED)
  // =====================================
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dan Sandi tidak boleh kosong"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    /// 🔥 SEKARANG LOGIN RETURN ROLE
    final String? role = await authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    // =====================================
    // NAVIGASI BERDASARKAN ROLE
    // =====================================
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_home');

    } else if (role == 'petugas') {
      Navigator.pushReplacementNamed(context, '/petugas_home');

    } else if (role == 'peminjam') {
      Navigator.pushReplacementNamed(context, '/peminjam_home');

    } else {
      /// selain 3 role = error message dari AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(role ?? "Login gagal"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================
  // UI
  // =====================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Text(
                    "Welcome to MyBrantas",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Temukan kebutuhan peminjaman perangkat digitalmu.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // EMAIL
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Sandi",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4C90),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "MASUK",
                              style: TextStyle(color: Colors.white),
                            ),
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

  // =====================================
  // HEADER UI
  // =====================================
  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF1E4C90),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(160),
              bottomRight: Radius.circular(160),
            ),
          ),
        ),
        const Positioned(
          top: 80,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                child: Icon(Icons.devices_other, size: 60),
              ),
              SizedBox(height: 10),
              Text(
                "MY BRANTAS ID",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
