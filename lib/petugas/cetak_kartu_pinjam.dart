import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CetakKartuPinjamPage extends StatelessWidget {
  final int idPeminjaman;
  final supabase = Supabase.instance.client;

  CetakKartuPinjamPage({super.key, required this.idPeminjaman});

  // --- FUNGSI UTAMA UNTUK GENERATE PDF ---
  Future<void> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final String tanggalCetak = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text("LAPORAN PEMINJAMAN ALAT", 
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Nama Peminjam: ${data['users']['nama']}"),
              pw.Text("Email: ${data['users']['email'] ?? "-"}"),
              pw.Text("Tanggal Pinjam: ${data['tanggal_pinjam']}"),
              pw.SizedBox(height: 20),
              
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: ['No', 'Nama Alat', 'Jumlah', 'Status'],
                data: [
                  ['1', '${data['alat']['nama_alat']}', '1 unit', '${data['status'].toString().toUpperCase()}'],
                ],
              ),
              
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  children: [
                    pw.Text("Dicetak pada: $tanggalCetak"),
                    pw.SizedBox(height: 40),
                    pw.Text("( Petugas Inventaris )", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                )
              )
            ],
          );
        },
      ),
    );

    // Membuka pratinjau cetak sistem
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Pinjam_${data['users']['nama']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Pratinjau Kartu Pinjam", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Tombol Cetak di Pojok Kanan Atas
          FutureBuilder(
            future: supabase.from('peminjaman').select('*, users(nama, email), alat(nama_alat)').eq('id_peminjaman', idPeminjaman).single(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () => _generatePdf(snapshot.data as Map<String, dynamic>),
                );
              }
              return const SizedBox();
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: supabase
            .from('peminjaman')
            .select('*, users(nama, email), alat(nama_alat)')
            .eq('id_peminjaman', idPeminjaman)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text("Gagal mengambil data peminjaman"));
          }
          
          final data = snapshot.data as Map<String, dynamic>;
          final String namaPetugas = "Clara"; 
          final String tanggalCetak = DateFormat('dd/MM/yyyy').format(DateTime.now());

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          _buildHeaderCetak(data['users']['nama'] ?? "User"),
                          const SizedBox(height: 20),
                          _buildInfoTable(namaPetugas, data['users']['email'] ?? "-", tanggalCetak),
                          const SizedBox(height: 30),
                          _buildDetailAlat(data),
                          const SizedBox(height: 40),
                          _buildFooterNote(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Tombol Cetak Melayang di Bawah
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _generatePdf(data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("CETAK LAPORAN PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET UI KOMPONEN (TETAP SAMA NAMUN DENGAN PERBAIKAN) ---

  Widget _buildHeaderCetak(String nama) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1E4C90),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Color(0xFF1E4C90))),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Peminjam Alat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(nama, style: const TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoTable(String petugas, String email, String tgl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF4A90E2),
            child: const Center(child: Text("INFORMASI TRANSAKSI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          _rowInfo("Petugas Lapangan:", petugas),
          _rowInfo("Email User:", email),
          _rowInfo("Tanggal Cetak:", tgl),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailAlat(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Waktu Pinjam: ${data['tanggal_pinjam'] ?? "-"}", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E4C90))),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FixedColumnWidth(40), 1: FlexColumnWidth(), 2: FixedColumnWidth(80)},
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFE3F2FD)),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Nama Alat", style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(8), child: Text("1")),
                  Padding(padding: const EdgeInsets.all(8), child: Text(data['alat']['nama_alat'] ?? "-")),
                  Padding(padding: const EdgeInsets.all(8), child: Text(data['status'] ?? "-")),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      color: Colors.blue[50],
      child: const Text(
        "Laporan ini sah dan dihasilkan secara otomatis oleh sistem sebagai bukti peminjaman.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
      ),
    );
  }
}