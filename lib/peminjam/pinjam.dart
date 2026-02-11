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
  String selectedFilter = "semua";

  // ================= GET DATA =================
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
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPeminjamanData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var data = snapshot.data!;

                if (selectedFilter != "semua") {
                  data = data
                      .where((e) => e['status'] == selectedFilter)
                      .toList();
                }

                if (data.isEmpty) {
                  return const Center(child: Text("Tidak ada data"));
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: data.length,
                    itemBuilder: (_, i) => _buildPinjamCard(data[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    final email = widget.userData?['email'] ??
        supabase.auth.currentUser?.email ??
        'user@gmail.com';

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF1E4C90)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Halo Peminjam",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FILTER BOX (FIXED 92x45) =================
  Widget _buildFilterChips() {
    final filters = ["semua", "menunggu", "disetujui", "selesai"];

    return SizedBox(
      height: 75,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final active = selectedFilter == f;

          return GestureDetector(
            onTap: () => setState(() => selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 92,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E4C90) : Colors.white,
                // ✅ Diubah menjadi Kotak (Radius kecil)
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(
                  color: active ? const Color(0xFF1E4C90) : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: active ? [
                  BoxShadow(
                    color: const Color(0xFF1E4C90).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Text(
                f[0].toUpperCase() + f.substring(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: active ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= CARD =================
  Widget _buildPinjamCard(Map<String, dynamic> data) {
    final detailList = data['detail_peminjaman'] as List?;
    final firstAlat = (detailList != null && detailList.isNotEmpty)
        ? detailList[0]['alat']
        : null;

    final nama = firstAlat?['nama_alat'] ?? 'Detail Pengajuan';
    final gambar = firstAlat?['gambar_alat'] ?? '';
    final status = data['status'];

    Color color = Colors.orange;
    if (status == 'disetujui') color = Colors.blue;
    if (status == 'selesai') color = Colors.green;
    if (status == 'ditolak') color = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: gambar.isNotEmpty
                      ? Image.network(gambar, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.inventory, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 5),
                    Text(
                      "${_formatDate(data['tanggal_pinjam'])} - ${_formatDate(data['tanggal_kembali'])}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 0.8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4C90),
                foregroundColor: Colors.white, 
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Detail", 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPeminjamanPage(data: data),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final d = DateTime.parse(dateStr);
    return "${d.day}/${d.month}/${d.year}";
  }
}