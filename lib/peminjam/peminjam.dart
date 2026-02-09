import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart'; 
import '../auth/logout.dart';  
import 'peminjam_alat.dart'; 
import 'pinjam.dart';

class PeminjamPage extends StatefulWidget {
  const PeminjamPage({super.key});

  @override
  State<PeminjamPage> createState() => _PeminjamPageState();
}

class _PeminjamPageState extends State<PeminjamPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // LOGIKA SUPABASE: Stream data peminjaman milik user yang sedang login
  Stream<List<Map<String, dynamic>>> _getPeminjamanStream(String userId) {
    return Supabase.instance.client
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('id_user', userId) 
        .order('created_at', ascending: false); // Ubah ke false agar data terbaru di atas
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;
    final String userId = user?['id'] ?? ''; 

    // LIST HALAMAN TERHUBUNG
    final List<Widget> _pages = [
      _buildBerandaPeminjam(user, userId),     // Index 0
      const AlatPeminjamPage(),               // Index 1: Tersambung ke alat.dart
      const PinjamPage(), // Index 2
      const Center(child: Text("Halaman Riwayat Kembali")), // Index 3
      const LogoutScreen(),                   // Index 4
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
          BottomNavigationBarItem(icon: Icon(Icons.computer), label: 'Alat'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_add), label: 'Pinjam'),
          BottomNavigationBarItem(icon: Icon(Icons.published_with_changes), label: 'Kembali'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildBerandaPeminjam(Map<String, dynamic>? user, String userId) {
    return Column(
      children: [
        // 1. Header Profil (Biru)
        _buildHeader(user),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Tombol Aksi Cepat
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        "Pinjam Alat", 
                        Icons.add_circle, 
                        Colors.green, 
                        () => _onItemTapped(1) // Arahkan ke tab Alat (Index 1)
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildQuickAction(
                        "Kembalikan", 
                        Icons.assignment_return, 
                        Colors.orange, 
                        () => _onItemTapped(3) // Arahkan ke tab Kembali (Index 3)
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                const Text("Status Peminjaman Anda",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // 3. List Data Real-time dari Supabase
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getPeminjamanStream(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox, size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Belum ada peminjaman.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length > 5 ? 5 : data.length, 
                      itemBuilder: (context, index) {
                        final item = data[index];
                        return _buildStatusCard(
                          item['nama_alat'] ?? 'Alat', // Sesuaikan kolom di DB Anda
                          item['status'] ?? 'menunggu',
                          item['created_at']?.toString().substring(0, 10) ?? '-',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget: Header (Dipisahkan agar rapi)
  Widget _buildHeader(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hallo Peminjam",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user?['email'] ?? 'peminjam@gmail.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF1E4C90), size: 35),
          )
        ],
      ),
    );
  }

  // Widget: Kartu Status Peminjaman
  Widget _buildStatusCard(String title, String status, String date) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'disetujui': statusColor = Colors.blue; break;
      case 'selesai': statusColor = Colors.green; break;
      case 'menunggu': statusColor = Colors.orange; break;
      case 'ditolak': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E4C90).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2, color: Color(0xFF1E4C90)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Tanggal: $date"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}