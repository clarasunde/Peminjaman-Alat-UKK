import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'detail_setuju.dart'; // Pastikan file detail_setuju.dart sudah ada

class PersetujuanPage extends StatefulWidget {
  const PersetujuanPage({super.key});

  @override
  State<PersetujuanPage> createState() => _PersetujuanPageState();
}

class _PersetujuanPageState extends State<PersetujuanPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Query Relasi Lengkap
  Future<List<Map<String, dynamic>>> _getPeminjamanData(String status) async {
    try {
      final response = await supabase
          .from('peminjaman')
          .select('''
            *,
            users(nama, email),
            detail_peminjaman(
              jumlah,
              alat(id_alat, nama_alat, gambar_alat)
            )
          ''')
          .eq('status', status)
          .order('id_peminjaman', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
      rethrow; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        title: const Text("Persetujuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Menunggu"),
            Tab(text: "Disetujui"),
            Tab(text: "Ditolak"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab('menunggu'),
          _buildListTab('disetujui'),
          _buildListTab('ditolak'),
        ],
      ),
    );
  }

  Widget _buildListTab(String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPeminjamanData(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Tidak ada data $status", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) => _buildRequestCard(data[i]),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    final user = item['users'] ?? {};
    final List details = item['detail_peminjaman'] ?? [];
    if (details.isEmpty) return const SizedBox();

    final detail = details.first;
    final alat = detail['alat'] ?? {};
    final imageUrl = alat['gambar_alat'];

    final tanggal = item['tanggal_pinjam'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['tanggal_pinjam']))
        : '-';

    return GestureDetector(
      onTap: () async {
        // Navigasi ke DetailSetujuPage dan menunggu hasil balik (true/false)
        final refresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailSetujuPage(item: item),
          ),
        );

        if (refresh == true) {
          setState(() {}); // Refresh data jika ada perubahan status di halaman detail
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto Alat
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (imageUrl != null && imageUrl.toString().isNotEmpty)
                    ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                    : Container(width: 70, height: 70, color: Colors.grey[100], child: const Icon(Icons.image)),
              ),
              const SizedBox(width: 12),
              // Info Peminjam & Alat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nama'] ?? 'Tanpa Nama', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("${alat['nama_alat']} (${detail['jumlah']} Unit)", 
                        style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(tanggal, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              // Icon Panah / Status
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}