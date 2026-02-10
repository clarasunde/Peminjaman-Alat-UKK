import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  // FUNGSI BARU: Mengambil huruf pertama dari nama secara otomatis
  String _generateInitial(String? nama) {
    if (nama == null || nama.isEmpty || nama == 'User') return "U";
    
    // Mengambil karakter pertama dan menjadikannya huruf kapital
    return nama[0].toUpperCase(); 
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;
    
    // Mengambil data real-time dari database (tabel public.users)
    String namaUser = user?['nama']?.toString() ?? 'User'; 
    String roleUser = user?['role']?.toString() ?? 'peminjam';
    String emailUser = user?['email'] ?? 'email@gmail.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        title: const Text("Pengaturan", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profil Otomatis Berdasarkan Nama
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E4C90),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hallo $namaUser", 
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          emailUser, 
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // AVATAR INISIAL OTOMATIS (Sekarang menggunakan namaUser)
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Text(
                      _generateInitial(namaUser), // Memanggil fungsi dengan parameter nama
                      style: const TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. Form Informasi Dinamis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  _buildInfoField("Nama Akun", namaUser),
                  _buildInfoField("Email Terdaftar", emailUser),
                  _buildInfoField("Kata Sandi", "********"),
                  _buildInfoField("Level Akses", roleUser.toUpperCase()), 
                  
                  const SizedBox(height: 50),

                  // 3. Tombol Keluar
                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4C90),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: () => _showLogoutDialog(context, authService),
                      child: const Text("Keluar", style: TextStyle(color: Colors.white, fontSize: 18)),
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

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: value,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Apakah anda yakin ingin keluar dari akun ini?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}