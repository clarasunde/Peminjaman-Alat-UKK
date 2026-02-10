import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'detail_setuju.dart';
import '../models/peminjaman_model.dart';

// ✅ PERBAIKAN 1: Buat Enum untuk Type Safety
enum StatusPeminjaman {
  menunggu,
  disetujui,
  ditolak,
  selesai
}

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

  // ✅ Stream dengan Join Relasi (Real-time Updates)
  Stream<List<Map<String, dynamic>>> _getPeminjamanStream(String status) {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('status', status) // ✅ Sudah lowercase dari parameter
        .order('id_peminjaman', ascending: false)
        .asyncMap((data) async {
      // Manual join karena stream tidak support nested select
      List<Map<String, dynamic>> results = [];
      
      for (var item in data) {
        try {
          // Ambil data user
          final user = await supabase
              .from('users')
              .select('nama, email')
              .eq('id_user', item['id_user'])
              .maybeSingle();

          // Ambil detail peminjaman
          final details = await supabase
              .from('detail_peminjaman')
              .select('jumlah, id_alat')
              .eq('id_peminjaman', item['id_peminjaman']);

          // Ambil data alat untuk setiap detail
          List<Map<String, dynamic>> detailsWithAlat = [];
          for (var detail in details) {
            final alat = await supabase
                .from('alat')
                .select('id_alat, nama_alat, gambar_alat')
                .eq('id_alat', detail['id_alat'])
                .maybeSingle();
            
            detailsWithAlat.add({
              'jumlah': detail['jumlah'],
              'alat': alat ?? {},
            });
          }

          results.add({
            ...item,
            'users': user ?? {},
            'detail_peminjaman': detailsWithAlat,
          });
        } catch (e) {
          debugPrint("Error fetching nested data: $e");
        }
      }
      
      return results;
    });
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
          // ✅ PERBAIKAN 2: Gunakan lowercase untuk query
          _buildListTab(StatusPeminjaman.menunggu.name),
          _buildListTab(StatusPeminjaman.disetujui.name),
          _buildListTab(StatusPeminjaman.ditolak.name),
        ],
      ),
    );
  }

  Widget _buildListTab(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPeminjamanStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Gagal memuat data",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'menunggu' ? Icons.inbox_outlined : Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "Tidak ada permintaan ${_getStatusLabel(status)}",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (_, i) => _buildRequestCard(data[i], status),
        );
      },
    );
  }

  // ✅ Helper untuk label status yang user-friendly
  String _getStatusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'menunggu';
      case 'disetujui':
        return 'disetujui';
      case 'ditolak':
        return 'ditolak';
      default:
        return status;
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> item, String status) {
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
      child: InkWell(
        onTap: () async {
          // ✅ PERBAIKAN 3: Navigasi ke detail dengan callback
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSetujuPage(item: item),
            ),
          );
          
          // Tidak perlu setState, StreamBuilder otomatis update
          if (result != null && result == true) {
            debugPrint("Status berhasil diupdate, stream akan auto-refresh");
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.devices, size: 30, color: Colors.grey),
                  ),
            title: Text(
              user['nama'] ?? 'Tanpa Nama',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Alat: ${alat['nama_alat'] ?? '-'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Jumlah: ${detail['jumlah'] ?? 0}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tgl Pinjam: $tanggal",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            trailing: _buildStatusBadge(status),
          ),
        ),
      ),
    );
  }

  // ✅ PERBAIKAN 4: Widget badge status yang lebih baik
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'menunggu':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'MENUNGGU';
        break;
      case 'disetujui':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'DISETUJUI';
        break;
      case 'ditolak':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'DITOLAK';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}