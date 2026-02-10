import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_peminjaman.dart';

class PinjamPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PinjamPage({super.key, this.userData});

  @override
  State<PinjamPage> createState() => _PinjamPageState();
}

class _PinjamPageState extends State<PinjamPage> {
  final supabase = Supabase.instance.client;

  // Fungsi untuk mengambil data dengan relasi JOIN (Alat & Gambar)
  Future<List<Map<String, dynamic>>> _getPeminjamanData() async {
    final response = await supabase
        .from('peminjaman')
        .select('''
          *,
          detail_peminjaman (
            jumlah,
            alat (
              nama_alat,
              gambar_alat
            )
          )
        ''')
        .eq('id_user', supabase.auth.currentUser!.id)
        .order('tanggal_pinjam', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPeminjamanData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final dataPeminjaman = snapshot.data ?? [];

                if (dataPeminjaman.isEmpty) {
                  return const Center(child: Text("Belum ada riwayat pengajuan."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: dataPeminjaman.length,
                  itemBuilder: (context, index) {
                    final item = dataPeminjaman[index];
                    return _buildPinjamCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String userEmail = widget.userData?['email'] ?? 
                             supabase.auth.currentUser?.email ?? 
                             'peminjam@gmail.com';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30)
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25, 
            backgroundColor: Colors.white, 
            child: Icon(Icons.person, size: 30, color: Color(0xFF1E4C90))
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hallo Peminjam", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              Text(
                userEmail, 
                style: const TextStyle(color: Colors.white70, fontSize: 13)
              ),
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                  SizedBox(width: 5),
                  Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinjamCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'menunggu'; 
    
    // Mengambil data alat pertama untuk ditampilkan di thumbnail card
    final detailList = data['detail_peminjaman'] as List?;
    final firstAlat = (detailList != null && detailList.isNotEmpty) ? detailList[0]['alat'] : null;
    final String namaAlatTampilan = firstAlat?['nama_alat'] ?? 'Detail Pengajuan';
    final String urlGambar = firstAlat?['gambar_alat'] ?? '';

    Color statusColor = status == 'disetujui' ? Colors.green : 
                       status == 'ditolak' ? Colors.red : Colors.orange;
    Color bgColor = statusColor.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Gambar Alat dari Supabase
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60, height: 60,
                  color: Colors.grey[200],
                  child: urlGambar.isNotEmpty 
                    ? Image.network(urlGambar, fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                    : const Icon(Icons.inventory_2, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaAlatTampilan, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      "${_formatDate(data['tanggal_pinjam'])} s/d ${_formatDate(data['tanggal_kembali'])}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 11)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Riwayat Pengajuan", 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman detail baru yang Anda buat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPeminjamanPage(data: data),
                    ),
                  ).then((_) => setState(() {})); // Refresh saat kembali
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4C90),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text("Lihat Detail", 
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              )
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}