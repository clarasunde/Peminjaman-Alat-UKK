import 'package:flutter/material.dart';
import 'beranda.dart'; 
import 'kelola_alat.dart'; // 1. PASTIKAN IMPORT INI ADA
import '../auth/logout.dart'; 

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // 2. KATA 'const' DI DEPAN LIST DIHAPUS agar bisa memuat halaman dinamis
 final List<Widget> _pages = [
  const BerandaPage(),
  const Center(child: Text("Halaman Pengguna")),
  KelolaAlatPage(), // <--- Hapus 'const' nya saja
  const Center(child: Text("Halaman Riwayat")),
  const LogoutScreen(),
];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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