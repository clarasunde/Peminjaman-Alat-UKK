import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LaporanPengembalianPage extends StatelessWidget {
      LaporanPengembalianPage({super.key}); // Tambahkan constructor

  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Pengembalian", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(child: _buildDataTable()),
          _buildFooterAction(context), // Kirim context ke sini
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
                hintText: "Cari ID Peminjaman...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text("Filter"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('pengembalian').stream(primaryKey: ['id_pengembalian']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data pengembalian"));
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("ID Pinjam")),
                DataColumn(label: Text("Tgl Kembali")),
                DataColumn(label: Text("Denda")),
                DataColumn(label: Text("Status")),
              ],
              rows: data.map((item) {
                return DataRow(cells: [
                  DataCell(Text(item['id_peminjaman'].toString())),
                  DataCell(Text(item['tanggal_kembali']?.toString() ?? "-")),
                  DataCell(Text("Rp ${item['total_denda']}")),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['status'] == 'Lunas' ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item['status'] ?? "Pending",
                        style: TextStyle(
                          color: item['status'] == 'Lunas' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            print("Tombol Cetak PDF Ditekan");
            // Logika export PDF di sini
          },
          icon: const Icon(Icons.print),
          label: const Text("Cetak Laporan PDF"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E4C90), 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}