import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/pengguna_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth/auth_service.dart';
import '../auth/logout.dart';

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
  final supabase = Supabase.instance.client;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // AMBIL DATA DARI SUPABASE DENGAN TYPE CASTING YANG BENAR
  Stream<List<Map<String, dynamic>>> _getPieChartData() {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id'])
        .map((data) {
          Map<String, int> counts = {};
          for (var item in data) {
            String toolName = item['nama_alat'] ?? 'Tidak Diketahui';
            counts[toolName] = (counts[toolName] ?? 0) + 1;
          }

          var sortedList = counts.entries.map((e) => {
            'nama': e.key,
            'total': e.value
          }).toList();
          
          // PERBAIKAN SORTING: Gunakan type cast 'as int'
          sortedList.sort((a, b) {
            final bVal = b['total'] as int;
            final aVal = a['total'] as int;
            return bVal.compareTo(aVal);
          });
          
          return sortedList;
        });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    final List<Widget> _pages = [
      _buildBeranda(user),     
      const PenggunaPage(),    
      const AlatPage(),        
      const HalamanAdminLog(),  
      const LogoutScreen(),    
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
          BottomNavigationBarItem(icon: Icon(Icons.computer), label: 'Alat'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildBeranda(Map<String, dynamic>? user) {
    return Column(
      children: [
        _buildHeader(user),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Total Alat", "15"),
                    _buildStatCard("Dipinjam", "5"),
                    _buildStatCard("Tersedia", "10"),
                  ],
                ),
                const SizedBox(height: 25),
                _buildMonthlyChart(),
                const SizedBox(height: 25),
                const Text(
                  "Persentase Alat Sering Dipinjam",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E4C90)),
                ),
                const SizedBox(height: 15),
                _buildPieChartSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartSection() {
    final List<Color> colors = [Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPieChartData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Data tidak tersedia")));
        }

        final data = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      final int total = entry.value['total'] as int;
                      return PieChartSectionData(
                        color: colors[idx % colors.length],
                        value: total.toDouble(),
                        title: '$total',
                        radius: 50,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // PERBAIKAN LEGEND: Gunakan .map<Widget> dan toList() yang eksplisit
              Wrap(
                spacing: 15,
                runSpacing: 10,
                children: data.take(5).toList().asMap().entries.map<Widget>((entry) {
                  final int index = entry.key;
                  final String nama = entry.value['nama'].toString();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12, 
                        height: 12, 
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(nama, style: const TextStyle(fontSize: 11)),
                    ],
                  );
                }).toList(),
              )
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET PENDUKUNG TETAP SAMA ---

  Widget _buildHeader(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      width: double.infinity,
      color: const Color(0xFF1E4C90),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hallo Admin", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(user?['email'] ?? 'admin@gmail.com', style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Text("Online", style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF1E4C90), size: 35))
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF1E4C90), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Grafik Peminjaman", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("Total Peminjaman Bulan ini:", style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: const Text("Hari   Minggu   Bulan", style: TextStyle(fontSize: 10, color: Color(0xFF1E4C90))),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarChart("Jan", 20), _buildBarChart("Feb", 40), _buildBarChart("Mar", 30),
              _buildBarChart("Apr", 50), _buildBarChart("Mei", 70), _buildBarChart("Jun", 90),
              _buildBarChart("Jul", 60), _buildBarChart("Agu", 40), _buildBarChart("Sep", 55),
              _buildBarChart("Okt", 45), _buildBarChart("Nov", 30), _buildBarChart("Des", 25),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E4C90), borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.laptop_chromebook, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(count, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(String month, double height) {
    return Column(
      children: [
        Container(width: 8, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 5),
        Text(month, style: const TextStyle(color: Colors.white, fontSize: 8)),
      ],
    );
  }
}