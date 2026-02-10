import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPeminjamanPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailPeminjamanPage({super.key, required this.data});

  // Helper untuk format tanggal Indonesia
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // --- FUNGSI PROSES PENGEMBALIAN ---
  Future<void> _prosesPengembalian(BuildContext context) async {
    try {
      // 1. Tampilkan Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final idPeminjaman = data['id_peminjaman'];
      if (idPeminjaman == null) throw "ID Peminjaman tidak ditemukan";

      // 2. Insert ke tabel pengembalian
      await Supabase.instance.client.from('pengembalian').insert({
        'id_peminjaman': idPeminjaman,
        'tanggal_kembali': DateTime.now().toIso8601String(),
        'status_pembayaran': 'menunggu', 
      });

      // 3. Update status peminjaman menjadi 'selesai'
      // Menggunakan 'selesai' agar sesuai dengan ENUM di Database kamu
      await Supabase.instance.client
          .from('peminjaman')
          .update({'status': 'selesai'}) 
          .eq('id_peminjaman', idPeminjaman);

      if (context.mounted) {
        Navigator.pop(context); // Tutup Loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil mengembalikan alat!")),
        );
        Navigator.pop(context, true); // Kembali & refresh halaman sebelumnya
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Tutup loading
      
      String pesanError = e.toString();
      
      // Deteksi error Enum (22P02) atau RLS (42501)
      if (pesanError.contains("22P02")) {
        pesanError = "Gagal: Status 'selesai' tidak terdaftar di database.";
      } else if (pesanError.contains("row-level security") || pesanError.contains("42501")) {
        pesanError = "Izin ditolak (RLS). Silahkan aktifkan Policy INSERT di tabel 'pengembalian' pada dashboard Supabase.";
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Gagal Simpan"),
            content: Text(pesanError),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("Tutup")
              )
            ],
          ),
        );
      }
    }
  }

  // --- FUNGSI BATAL PEMINJAMAN ---
  Future<void> _batalPeminjaman(BuildContext context) async {
    try {
      final idPeminjaman = data['id_peminjaman'];
      
      await Supabase.instance.client
          .from('peminjaman')
          .delete()
          .eq('id_peminjaman', idPeminjaman);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Peminjaman berhasil dibatalkan")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membatalkan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString().toLowerCase() ?? 'menunggu';
    final isDisetujui = status == 'disetujui';
    final isMenunggu = status == 'menunggu';
    final details = data['detail_peminjaman'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isDisetujui ? 'Detail Peminjaman' : 'Status Pengajuan'),
        backgroundColor: const Color(0xFF1E4C90),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(isDisetujui, status),
            const SizedBox(height: 25),
            const Text("Informasi Waktu", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildInfoCard(data),
            const SizedBox(height: 25),
            const Text("Daftar Alat yang Dipinjam:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...details.map((d) => _buildAlatItem(d)).toList(),
            const SizedBox(height: 40),
            
            // --- TOMBOL AKSI ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Tutup", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 15),
                if (isDisetujui || isMenunggu)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isDisetujui) {
                        _prosesPengembalian(context);
                      } else {
                        _batalPeminjaman(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4C90),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isDisetujui ? "Kembalikan Alat" : "Batalkan Pesanan",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildStatusBanner(bool isDisetujui, String status) {
    Color color = isDisetujui ? Colors.green : Colors.orange;
    if (status == 'ditolak') color = Colors.red;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(isDisetujui ? Icons.check_circle : Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDisetujui 
                ? "Disetujui. Silahkan kembalikan alat jika sudah selesai digunakan."
                : (status == 'ditolak' ? "Pengajuan Ditolak." : "Menunggu konfirmasi petugas."),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlatItem(Map detail) {
    final alat = detail['alat'] ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            alat['gambar_alat'] ?? '',
            width: 50, height: 50, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 40),
          ),
        ),
        title: Text(alat['nama_alat'] ?? 'Alat', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Jumlah: ${detail['jumlah']} unit"),
      ),
    );
  }

  Widget _buildInfoCard(Map item) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _rowInfo("Tanggal Pinjam", _formatDate(item['tanggal_pinjam'])),
          const Divider(height: 20),
          _rowInfo("Rencana Kembali", _formatDate(item['tanggal_kembali'])),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}