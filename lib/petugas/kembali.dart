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

  Stream<List<Map<String, dynamic>>> _getKembaliStream(String status) {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('status', status);
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
            Tab(text: "Pengembalian"),
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
    // Perhitungan denda konsisten: 10rb/hari
    DateTime tglTenggat = DateTime.parse(item['tanggal_kembali']);
    DateTime tglSekarang = DateTime.now();
    
    // .difference menghasilkan durasi, .inDays menghitung selisih 24 jam penuh
    int selisihHari = tglSekarang.difference(tglTenggat).inDays;
    const int tarifDenda = 10000; 
    int totalDenda = selisihHari > 0 ? selisihHari * tarifDenda : 0;

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
                const CircleAvatar(
                  backgroundColor: Color(0xFF1E4C90), 
                  child: Icon(Icons.person, color: Colors.white)
                ),
                const SizedBox(width: 12),
                const Text("Peminjam Terdaftar", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (item['status'] == 'selesai') _statusBadge("Selesai", Colors.green),
              ],
            ),
            const Divider(height: 24),
            Text("ID Alat: ${item['id_alat']}", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            _infoRow("Tgl Pinjam", item['tanggal_pinjam']),
            _infoRow("Tgl Tenggat", item['tanggal_kembali']),
            const SizedBox(height: 12),
            
            if (item['status'] == 'disetujui') ...[
              if (selisihHari > 0) 
                _warningDenda("Terlambat $selisihHari Hari - Denda: Rp ${NumberFormat('#,###').format(totalDenda)}"),
              
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _prosesValidasi(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4C90),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Validasi Pengembalian", 
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // LOGIKA DATABASE: Gabungan update status dan insert pengembalian
  Future<void> _prosesValidasi(Map<String, dynamic> item) async {
    try {
      DateTime tglTenggat = DateTime.parse(item['tanggal_kembali']);
      DateTime tglSekarang = DateTime.now();
      
      int selisihHari = tglSekarang.difference(tglTenggat).inDays;
      const int tarifDenda = 10000; 
      int totalDenda = selisihHari > 0 ? selisihHari * tarifDenda : 0;

      // 1. Update status di tabel 'peminjaman'
      await supabase
          .from('peminjaman')
          .update({'status': 'selesai'})
          .eq('id_peminjaman', item['id_peminjaman']);

      // 2. Insert ke tabel 'pengembalian'
      await supabase.from('pengembalian').insert({
        'id_peminjaman': item['id_peminjaman'],
        'tanggal_kembali': tglSekarang.toIso8601String(),
        'terlambat_hari': selisihHari > 0 ? selisihHari : 0,
        'denda_terlambat': totalDenda,
        'total_denda': totalDenda,
        'status': totalDenda > 0 ? 'Belum Lunas' : 'Lunas',
        'pesan_notif': totalDenda > 0 ? 'Ada denda keterlambatan' : 'Terima kasih',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil! Data pengembalian telah disimpan.")),
        );
      }
    } catch (e) {
      debugPrint("Gagal menyambungkan ke database: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, 
              child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Text(": $value", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
          Expanded(
            child: Text(text, 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
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
      child: Text(label, 
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}