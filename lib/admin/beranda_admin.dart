import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Profil Sesuai Figma (Biru Kotak Tanpa Rounded Bawah Berlebih)
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            width: double.infinity,
            color: const Color(0xFF1E4C90), // Biru gelap Brantas
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hallo Admin", // Sesuai teks di Figma
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                      user?['email'] ?? 'admin@gmail.com', // Teks email di bawah nama
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Text(
                      "Online", // Label status Online
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
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
                  // 2. Row Kartu Statistik (Biru dengan Ikon Laptop Putih)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Total Alat", "15"),
                      _buildStatCard("Dipinjam", "5"),
                      _buildStatCard("Tersedia", "10"),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 3. Grafik Peminjaman (Background Biru Gelap)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Grafik Peminjaman",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "Total Peminjaman Bulan ini:",
                              style: TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Tab Hari/Minggu/Bulan kecil
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text("Hari   Minggu   Bulan", style: TextStyle(fontSize: 10, color: Color(0xFF1E4C90))),
                        ),
                        const SizedBox(height: 20),
                        // Bar Chart Putih
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
      ),
    );
  }

  // Widget Kartu Statistik Biru Sesuai Figma
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
              const Icon(Icons.laptop_chromebook, color: Colors.white, size: 28), // Ikon laptop di Figma
              const SizedBox(width: 8),
              Text(
                count, 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Bar Chart Putih Tipis Sesuai Figma
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