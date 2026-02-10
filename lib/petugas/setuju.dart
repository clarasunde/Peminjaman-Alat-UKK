import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  // ✅ Query dengan Join Relasi (Membutuhkan Foreign Key di DB)
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
      // Menampilkan error di console untuk debugging
      debugPrint("Error Fetching Data: $e");
      rethrow; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        title: const Text("Persetujuan", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Gagal memuat data relasi.\nPastikan Foreign Key sudah diset di Supabase.\n\nError: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text("Tidak ada permintaan"));
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
    
    // Validasi jika detail kosong
    if (details.isEmpty) return const SizedBox();

    final detail = details.first;
    final alat = detail['alat'] ?? {};
    final imageUrl = alat['gambar_alat'];

    final tanggal = item['tanggal_pinjam'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['tanggal_pinjam']))
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: (imageUrl != null && imageUrl.toString().isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                  ),
                )
              : const Icon(Icons.image_not_supported, size: 40),
          title: Text(user['nama'] ?? 'Tanpa Nama', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.top(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Alat: ${alat['nama_alat'] ?? '-'}"),
                Text("Jumlah: ${detail['jumlah'] ?? 0}"),
                Text("Tgl Pinjam: $tanggal", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          trailing: item['status'] == 'menunggu'
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateStatus(item, 'disetujui'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateStatus(item, 'ditolak'),
                        ),
                      ],
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item['status'] == 'disetujui' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item['status'] == 'disetujui' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> item, String status) async {
    try {
      await supabase
          .from('peminjaman')
          .update({'status': status})
          .eq('id_peminjaman', item['id_peminjaman']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil: Permintaan $status")),
        );
        setState(() {}); // Segarkan UI
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }
}