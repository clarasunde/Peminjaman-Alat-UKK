import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // PERBAIKAN: Query Stream menggunakan Join ke detail_peminjaman dan alat
  Stream<List<Map<String, dynamic>>> _getKembaliStream(String status) {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('status', status)
        .map((data) => data.toList()); 
        // Note: Untuk relasi kompleks, sebaiknya gunakan FutureBuilder jika stream murni tabel sulit ditarik relasinya.
        // Namun kita akan optimasi di sisi tampilan dengan mengambil data detail secara async.
  }

  // Fungsi tambahan untuk mengambil info alat secara detail
  Future<Map<String, dynamic>?> _getDetailAlat(int idPeminjaman) async {
    final response = await supabase
        .from('detail_peminjaman')
        .select('*, alat(*)')
        .eq('id_peminjaman', idPeminjaman)
        .maybeSingle();
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengembalian", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Peminjaman"),
            Tab(text: "Selesai"),
            Tab(text: "Denda"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('disetujui'),
          _buildTabContent('selesai'),
          _buildTabContent('denda'),
        ],
      ),
    );
  }

  Widget _buildTabContent(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getKembaliStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return _buildKembaliCard(item);
          },
        );
      },
    );
  }

  Widget _buildKembaliCard(Map<String, dynamic> item) {
    DateTime tglTenggat = DateTime.parse(item['tanggal_kembali']);
    DateTime tglSekarang = DateTime.now();
    int selisihHari = tglSekarang.difference(tglTenggat).inDays;
    const int tarifDenda = 10000; 
    int totalDenda = selisihHari > 0 ? selisihHari * tarifDenda : 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getDetailAlat(item['id_peminjaman']),
      builder: (context, detailSnapshot) {
        final detailData = detailSnapshot.data;
        final alat = detailData?['alat'];
        final String namaAlat = alat?['nama_alat'] ?? "Memuat...";
        final String? urlGambar = alat?['gambar_alat'];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E4C90), 
                      backgroundImage: urlGambar != null ? NetworkImage(urlGambar) : null,
                      child: urlGambar == null ? const Icon(Icons.inventory_2, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(namaAlat, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Peminjam Terdaftar", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    if (item['status'] == 'selesai') _statusBadge("Selesai", Colors.green),
                  ],
                ),
                const Divider(height: 24),
                _infoRow("ID Peminjaman", "#${item['id_peminjaman']}"),
                _infoRow("Tgl Pinjam", item['tanggal_pinjam']),
                _infoRow("Tgl Tenggat", item['tanggal_kembali']),
                const SizedBox(height: 12),
                
                if (item['status'] == 'disetujui') ...[
                  if (selisihHari > 0) 
                    _warningDenda("Terlambat $selisihHari Hari - Estimasi Denda: Rp ${NumberFormat('#,###').format(totalDenda)}"),
                  
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _prosesValidasi(item, totalDenda, selisihHari),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4C90),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Validasi Pengembalian", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      }
    );
  }

  Future<void> _prosesValidasi(Map<String, dynamic> item, int totalDenda, int selisihHari) async {
    try {
      // 1. Update status di tabel 'peminjaman'
      await supabase
          .from('peminjaman')
          .update({'status': 'selesai'})
          .eq('id_peminjaman', item['id_peminjaman']);

      // 2. Insert ke tabel 'pengembalian' sesuai struktur tabel di gambar anda
      await supabase.from('pengembalian').insert({
        'id_peminjaman': item['id_peminjaman'],
        'tanggal_kembali': DateTime.now().toIso8601String(),
        'terlambat_hari': selisihHari > 0 ? selisihHari : 0,
        'total_denda': totalDenda,
        'status_pembayaran': totalDenda > 0 ? 'Belum Lunas' : 'Lunas', // Sesuaikan kolom image_0f623a.png
        'pesan_notif': totalDenda > 0 ? 'Denda Rp ${totalDenda}' : 'Tepat waktu',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil! Alat telah dikembalikan.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e")),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Text(": $value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _warningDenda(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.red.shade50, 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200)
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: color)
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}