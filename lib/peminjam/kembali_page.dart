import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class KembaliPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const KembaliPage({super.key, this.userData});

  @override
  State<KembaliPage> createState() => _KembaliPageState();
}

class _KembaliPageState extends State<KembaliPage>
    with SingleTickerProviderStateMixin {

  final supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ================= FORMAT =================
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  // ================= STREAM SEMUA =================
  Stream<List<Map<String, dynamic>>> _streamAll() {
    return supabase
        .from('pengembalian')
        .stream(primaryKey: ['id_pengembalian'])
        .order('id_pengembalian', ascending: false);
  }

  // ================= DETAIL =================
  Future<Map<String, dynamic>?> _getDetail(int idPeminjaman) async {
    return await supabase
        .from('peminjaman')
        .select('''
          *,
          detail_peminjaman (
            alat (nama_alat, gambar_alat)
          )
        ''')
        .eq('id_peminjaman', idPeminjaman)
        .maybeSingle();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Riwayat Pengembalian"),
        backgroundColor: const Color(0xFF1E4C90),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Selesai"),
          ],
        ),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamAll(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;

          // 🔥 FILTER DI SINI
          final menunggu =
              all.where((e) => e['status'] == 'menunggu').toList();

          final selesai =
              all.where((e) => e['status'] == 'selesai').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(menunggu),
              _buildList(selesai),
            ],
          );
        },
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i];

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getDetail(item['id_peminjaman']),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();
            return _buildCard(item, snap.data!);
          },
        );
      },
    );
  }

  // ================= CARD =================
  Widget _buildCard(
      Map<String, dynamic> pengembalian,
      Map<String, dynamic> peminjaman) {

    final details = peminjaman['detail_peminjaman'] as List? ?? [];
    final alat = details.isNotEmpty ? details[0]['alat'] : null;

    final status = pengembalian['status'];
    final denda = pengembalian['total_denda'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [

            SizedBox(
              width: 60,
              height: 60,
              child: alat?['gambar_alat'] != null
                  ? Image.network(alat['gambar_alat'])
                  : const Icon(Icons.inventory),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alat?['nama_alat'] ?? 'Alat',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${_formatDate(peminjaman['tanggal_pinjam'])} - ${_formatDate(peminjaman['tanggal_kembali'])}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  if (denda > 0)
                    Text(
                      "Denda: Rp ${NumberFormat('#,###').format(denda)}",
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                ],
              ),
            ),

            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  // ================= BADGE =================
  Widget _buildStatusBadge(String status) {
    final selesai = status == 'selesai';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selesai ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        selesai ? "Selesai" : "Menunggu",
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
