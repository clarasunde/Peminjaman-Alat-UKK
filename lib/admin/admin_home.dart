import 'package:flutter/material.dart';
import 'beranda_admin.dart'; 
import 'kelola_alat.dart'; 
import '../auth/logout.dart'; 

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // PERBAIKAN: List harus memiliki 5 item agar sesuai dengan BottomNavigationBar
  final List<Widget> _pages = [
    const BerandaPage(),                             // Index 0: Beranda
    const Center(child: Text("Halaman Pengguna")),   // Index 1: Pengguna
    const Center(child: Text("Halaman Alat")),       // Index 2: Alat
    const Center(child: Text("Halaman Riwayat")),    // Index 3: Riwayat
    const LogoutScreen(),                            // Index 4: Pengaturan (Logout)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan IndexedStack agar state halaman tidak hilang saat pindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1E4C90),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 26,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), 
              label: 'Beranda'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), 
              label: 'Pengguna'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded), 
              label: 'Alat'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded), 
              label: 'Riwayat'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), 
              label: 'Pengaturan'
            ),
          ],
        ),
      ),
    );
  }
}