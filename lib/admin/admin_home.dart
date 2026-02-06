import 'package:flutter/material.dart';
import 'beranda.dart'; // Import langsung karena berada di folder yang sama (lib/admin)

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // Daftar halaman sesuai ikon di desain Figma kamu
  final List<Widget> _pages = [
    const BerandaPage(), // Class dari file beranda.dart
    const Center(child: Text("Halaman Data Alat")),
    const Center(child: Text("Halaman Laporan Peminjaman")),
    const Center(child: Text("Halaman Akun Admin")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan IndexedStack agar state halaman tidak reset saat pindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1E4C90), // Biru sesuai desain
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), 
              label: 'Beranda'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), 
              label: 'Alat'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), 
              label: 'Laporan'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), 
              label: 'Akun'
            ),
          ],
        ),
      ),
    );
  }
}