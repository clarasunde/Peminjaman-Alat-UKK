import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mengambil data user dari Provider agar nama di header dinamis
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Profil Biru (Sesuai Desain Figma)
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4C90), // Warna biru utama
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hallo ${user?['nama'] ?? 'Admin'}", 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?['role']?.toUpperCase() ?? 'ADMIN',
                      style: const TextStyle(
                        color: Colors.white70, 
                        fontSize: 12, 
                        letterSpacing: 1.2
                      ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                )
              ],
            ),
          ),

          // 2. Area Konten (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Kartu Statistik
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Total Alat", "15", Icons.inventory_2),
                      _buildStatCard("Dipinjam", "5", Icons.pending_actions),
                      _buildStatCard("Tersedia", "10", Icons.check_circle_outline),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Bagian Grafik Statistik
                  const Text(
                    "Statistik Peminjaman",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Color(0xFF1E4C90)
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E4C90),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Aktivitas 7 Hari Terakhir", 
                          style: TextStyle(color: Colors.white70, fontSize: 12)
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) => _buildBarChart(index)),
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

  // Helper Widget untuk Kartu Statistik (Putih)
  Widget _buildStatCard(String title, String count, IconData icon) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 5, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1E4C90), size: 24),
          const SizedBox(height: 10),
          Text(
            count, 
            style: const TextStyle(
              color: Color(0xFF1E4C90), 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            )
          ),
          Text(
            title, 
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10)
          ),
        ],
      ),
    );
  }

  // Helper Widget untuk Bar Grafik
  Widget _buildBarChart(int index) {
    final heights = [50.0, 80.0, 60.0, 100.0, 70.0, 90.0, 55.0];
    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    
    return Column(
      children: [
        Container(
          width: 12,
          height: heights[index],
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(index == 3 ? 1.0 : 0.4), 
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          days[index], 
          style: const TextStyle(color: Colors.white, fontSize: 10)
        ),
      ],
    );
  }
}