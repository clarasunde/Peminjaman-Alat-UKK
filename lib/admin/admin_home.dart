import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/pengguna_page.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../auth/logout.dart';
// Import halaman lain tetap dipertahankan
import 'alat_page.dart'; 
import 'pengguna.dart';
import 'riwayat.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil data user untuk Beranda
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    // List halaman sekarang berisi fungsi internal untuk index 0
    final List<Widget> _pages = [
      _buildBeranda(user),     // 0: Beranda (Hasil Gabungan)
      const PenggunaPage(),    // 1: Pengguna
      const AlatPage(),        // 2: Alat
      const HalamanRiwayat(),  // 3: Riwayat
      const LogoutScreen(),    // 4: Pengaturan/Logout
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E4C90),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Alat'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
        ],
      ),
    );
  }

  // --- KONTEN BERANDA (PINDAHAN DARI BERANDA_ADMIN.DART) ---
  Widget _buildBeranda(Map<String, dynamic>? user) {
    return Column(
      children: [
        // 1. Header Profil
        Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
          width: double.infinity,
          color: const Color(0xFF1E4C90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hallo Admin",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?['email'] ?? 'admin@gmail.com',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const Text("Online",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E4C90), size: 35),
              )
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Kartu Statistik
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Total Alat", "15"),
                    _buildStatCard("Dipinjam", "5"),
                    _buildStatCard("Tersedia", "10"),
                  ],
                ),
                const SizedBox(height: 25),
                // 3. Grafik Peminjaman
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E4C90),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Grafik Peminjaman",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("Total Peminjaman Bulan ini:",
                              style: TextStyle(color: Colors.white70, fontSize: 9)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text("Hari   Minggu   Bulan",
                            style: TextStyle(fontSize: 10, color: Color(0xFF1E4C90))),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBarChart("Jan", 20),
                          _buildBarChart("Feb", 40),
                          _buildBarChart("Mar", 30),
                          _buildBarChart("Apr", 50),
                          _buildBarChart("Mei", 70),
                          _buildBarChart("Jun", 90),
                          _buildBarChart("Jul", 60),
                          _buildBarChart("Agu", 40),
                          _buildBarChart("Sep", 55),
                          _buildBarChart("Okt", 45),
                          _buildBarChart("Nov", 30),
                          _buildBarChart("Des", 25),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4C90),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.laptop_chromebook, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(count,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(String month, double height) {
    return Column(
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 5),
        Text(month, style: const TextStyle(color: Colors.white, fontSize: 8)),
      ],
    );
  }
}