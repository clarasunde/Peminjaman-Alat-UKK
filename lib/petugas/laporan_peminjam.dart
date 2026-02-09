import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cetak_kartu_pinjam.dart'; 

class LaporanPeminjamanPage extends StatelessWidget {
  LaporanPeminjamanPage({super.key});

  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Peminjaman",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          const SizedBox(height: 10),
          const Divider(thickness: 1, height: 1),
          Expanded(child: _buildDataTable()),
          // --- PENAMBAHAN TOMBOL SESUAI DESAIN ---
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // Widget Tombol Batal dan Cetak Laporan
 Widget _buildActionButtons(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    color: Colors.white,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tombol Batal
        SizedBox(
          width: 99,
          height: 43,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9D9D9),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: EdgeInsets.zero, // Menghilangkan padding default agar pas
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        // Tombol Cetak Laporan 
        SizedBox(
          width: 170, // ukuran cetak laporan
          height: 43,
          child: ElevatedButton(
            onPressed: () {
              // Logika cetak
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4C90),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8), // Padding kecil
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text(
                  "Cetak Laporan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  softWrap: false, // agar teks tidak turun kebawah
                  overflow: TextOverflow.visible, 
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari nama peminjam...",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildDataTable() {
    return FutureBuilder(
      future: supabase
          .from('peminjaman')
          .select('*, users(nama), alat(nama_alat)')
          .order('tanggal_pinjam', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text("Tidak ada data peminjaman."));
        }

        final data = snapshot.data as List<dynamic>;

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
              columns: const [
                DataColumn(label: Text("Nama Peminjam", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Alat", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Tgl Pinjam", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data.map((item) {
                final status = item['status']?.toString().toLowerCase() ?? "pending";
                return DataRow(cells: [
                  DataCell(Text(item['users']?['nama'] ?? "Anonim")),
                  DataCell(Text(item['alat']?['nama_alat'] ?? "Alat Dihapus")),
                  DataCell(Text(item['tanggal_pinjam'] ?? "-")),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status)),
                      ),
                    ),
                  ),
                  DataCell(
                    status == 'disetujui' || status == 'selesai'
                        ? IconButton(
                            icon: const Icon(Icons.print, color: Colors.blue, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CetakKartuPinjamPage(
                                      idPeminjaman: item['id_peminjaman']),
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.hourglass_empty, color: Colors.grey, size: 20),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disetujui': return Colors.blue;
      case 'selesai': return Colors.green;
      case 'ditolak': return Colors.red;
      default: return Colors.orange;
    }
  }
}