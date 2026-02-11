import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage>
    with SingleTickerProviderStateMixin {

  final supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // ================= FETCH =================
  Future<List<Map<String, dynamic>>> _fetch(String status) async {
    return await supabase
        .from('pengembalian')
        .select('''
          id_pengembalian,
          status,
          tanggal_kembali,
          total_denda,
          terlambat_hari,
          peminjaman (
            id_peminjaman,
            tanggal_pinjam,
            detail_peminjaman (
              alat (nama_alat, gambar_alat)
            )
          )
        ''')
        .eq('status', status)
        .order('id_pengembalian', ascending: false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengembalian"),
        backgroundColor: const Color(0xFF1E4C90),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Selesai"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab('menunggu', showApprove: true),
          _buildTab('selesai'),
        ],
      ),
    );
  }

  // ================= TAB =================
  Widget _buildTab(String status, {bool showApprove = false}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetch(status),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data!;
        if (list.isEmpty) {
          return const Center(child: Text("Tidak ada data"));
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _buildCard(list[i], showApprove),
          ),
        );
      },
    );
  }

  // ================= CARD =================
  Widget _buildCard(Map<String, dynamic> data, bool showApprove) {
    final peminjaman = data['peminjaman'];
    final detail = peminjaman['detail_peminjaman'] as List?;
    final alat = detail != null && detail.isNotEmpty ? detail[0]['alat'] : null;

    final denda = data['total_denda'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
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
                  child: Text(
                    alat?['nama_alat'] ?? 'Alat',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _statusBadge(data['status']),
              ],
            ),

            const SizedBox(height: 10),

            Text("ID: #${peminjaman['id_peminjaman']}"),
            Text(
              "Pinjam: ${DateFormat('dd MMM yyyy').format(DateTime.parse(peminjaman['tanggal_pinjam']))}",
            ),

            if (denda > 0)
              Text(
                "Denda: Rp ${NumberFormat('#,###').format(denda)}",
                style: const TextStyle(color: Colors.red),
              ),

            if (showApprove)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _approve(data['id_pengembalian']),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Setujui"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= APPROVE (FIX TERPENTING) =================
  Future<void> _approve(int id) async {
    try {
      final res = await supabase
          .from('pengembalian')
          .update({'status': 'selesai'})
          .eq('id_pengembalian', id)
          .select(); // 🔥 WAJIB

      debugPrint(res.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengembalian disetujui")),
      );

      setState(() {}); // refresh
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================= BADGE =================
  Widget _statusBadge(String status) {
    final color = status == 'selesai' ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
