import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';
import '../auth/logout.dart';
import 'setuju.dart';
import 'kembali.dart';
import 'laporan.dart';

class PetugasPage extends StatefulWidget {
  const PetugasPage({super.key});

  @override
  State<PetugasPage> createState() => _PetugasPageState();
}

class _PetugasPageState extends State<PetugasPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // LOGIKA SUPABASE: Hitung data real-time berdasarkan status enum
  Stream<Map<String, int>> _getStatsStream() {
    return Supabase.instance.client
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman']).map((data) {
      int menunggu = data.where((item) => item['status'] == 'menunggu').length;
      int dipinjam = data.where((item) => item['status'] == 'disetujui').length;
      int kembali = data.where((item) => item['status'] == 'selesai').length;
      return {'menunggu': menunggu, 'dipinjam': dipinjam, 'kembali': kembali};
    });
  }

  // STREAM UNTUK PERMINTAAN TERBARU dari Supabase
  Stream<List<Map<String, dynamic>>> _getPermintaanTerbaruStream() {
    return Supabase.instance.client
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('status', 'menunggu')
        .order('tanggal_pinjam', ascending: false)
        .limit(5)
        .map((data) async {
          List<Map<String, dynamic>> hasil = [];
          
          for (var peminjaman in data) {
            try {
              // Ambil data user
              final user = await Supabase.instance.client
                  .from('users')
                  .select('nama, email')
                  .eq('id_user', peminjaman['id_user'])
                  .maybeSingle();

              // Ambil detail peminjaman pertama (untuk dapat id_alat)
              final detailPeminjaman = await Supabase.instance.client
                  .from('detail_peminjaman')
                  .select('id_alat, jumlah')
                  .eq('id_peminjaman', peminjaman['id_peminjaman'])
                  .limit(1)
                  .maybeSingle();

              String namaAlat = 'Alat tidak tersedia';
              if (detailPeminjaman != null) {
                // Ambil nama alat
                final alat = await Supabase.instance.client
                    .from('alat')
                    .select('nama_alat')
                    .eq('id_alat', detailPeminjaman['id_alat'])
                    .maybeSingle();
                
                if (alat != null) {
                  namaAlat = alat['nama_alat'];
                }
              }

              hasil.add({
                'id_peminjaman': peminjaman['id_peminjaman'],
                'nama': user?['nama'] ?? 'User tidak diketahui',
                'email': user?['email'] ?? '',
                'nama_alat': namaAlat,
                'tanggal_pinjam': peminjaman['tanggal_pinjam'],
              });
            } catch (e) {
              print('Error fetching data: $e');
            }
          }
          
          return hasil;
        })
        .asyncMap((future) => future);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    final List<Widget> _pages = [
      _buildBerandaPetugas(user),
      const PersetujuanPage(),
      const PengembalianPage(),
      const LaporanPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Setuju'),
          BottomNavigationBarItem(icon: Icon(Icons.published_with_changes), label: 'Kembali'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildBerandaPetugas(Map<String, dynamic>? user) {
    return Column(
      children: [
        // 1. Header Profil
        Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
          width: double.infinity,
          color: const Color(0xFF1E4C90),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hallo Petugas",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?['email'] ?? 'petugas1@gmail.com',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const Text("Online",
                      style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E4C90), size: 35),
              )
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Kartu Statistik (REAL-TIME SUPABASE)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E4C90),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: StreamBuilder<Map<String, int>>(
                    stream: _getStatsStream(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {'menunggu': 0, 'dipinjam': 0, 'kembali': 0};
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(label: "Persetujuan", count: "${stats['menunggu']}"),
                          const _VerticalLine(),
                          _StatItem(label: "Dipinjam", count: "${stats['dipinjam']}"),
                          const _VerticalLine(),
                          _StatItem(label: "Kembali", count: "${stats['kembali']}"),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),
                const Text("Permintaan Terbaru",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // 3. PERMINTAAN TERBARU - REAL-TIME dari Supabase
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getPermintaanTerbaruStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final permintaan = snapshot.data ?? [];

                    if (permintaan.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Tidak ada permintaan baru',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    return Column(
                      children: permintaan.map((item) {
                        return _buildRequestItem(
                          item['nama'],
                          item['email'],
                          item['nama_alat'],
                          _formatTanggal(item['tanggal_pinjam']),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // 4. BAGIAN MENU KOTAK (GRID) dengan fungsi Navigasi
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 2.5,
                  children: [
                    _buildMenuTile(Icons.person, "Setujui", "Peminjaman", () => _onItemTapped(1)),
                    _buildMenuTile(Icons.settings, "Pengaturan", "Keluar", () => _onItemTapped(4)),
                    _buildMenuTile(Icons.computer, "Proses", "Pengembalian", () => _onItemTapped(2)),
                    _buildMenuTile(Icons.bar_chart, "Cetak", "Laporan", () => _onItemTapped(3)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper function untuk format tanggal
  String _formatTanggal(String? tanggal) {
    if (tanggal == null) return '-';
    try {
      final date = DateTime.parse(tanggal);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return tanggal;
    }
  }

  Widget _buildRequestItem(String name, String email, String device, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.blue.shade100, child: Text(name[0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Text("Menunggu Persetujuan", style: TextStyle(fontSize: 9, color: Colors.orange)),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.laptop, size: 40, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subTitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _VerticalLine extends StatelessWidget {
  const _VerticalLine();
  @override
  Widget build(BuildContext context) {
    return Container(height: 30, width: 1, color: Colors.white24);
  }
}