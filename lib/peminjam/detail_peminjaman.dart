import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPeminjamanPage extends StatelessWidget {
  final Map<String, dynamic> data;

  DetailPeminjamanPage({super.key, required this.data});

  final supabase = Supabase.instance.client;

  // ================= KONFIGURASI DENDA =================
  final int tarifDendaPerHari = 10000;

  // ================= FORMAT TANGGAL =================
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  // ================= LOGIC HITUNG TELAT & DENDA =================
  Map<String, dynamic> _hitungKeterlambatan() {
    if (data['tanggal_kembali'] == null) return {'hari': 0, 'total': 0};

    try {
      DateTime tenggat = DateTime.parse(data['tanggal_kembali']);
      DateTime sekarang = DateTime.now();

      // Normalisasi waktu ke tengah malam agar hitungan hari akurat
      DateTime tenggatDate = DateTime(tenggat.year, tenggat.month, tenggat.day);
      DateTime sekarangDate = DateTime(sekarang.year, sekarang.month, sekarang.day);

      if (sekarangDate.isAfter(tenggatDate)) {
        int selisih = sekarangDate.difference(tenggatDate).inDays;
        return {
          'hari': selisih,
          'total': selisih * tarifDendaPerHari,
        };
      }
    } catch (e) {
      debugPrint("Error hitung denda: $e");
    }
    return {'hari': 0, 'total': 0};
  }

  // ================= AJUKAN PENGEMBALIAN =================
  Future<void> _prosesPengembalian(BuildContext context) async {
    final id = data['id_peminjaman'];
    final infoDenda = _hitungKeterlambatan();

    try {
      if (id == null) throw "ID peminjaman tidak ditemukan.";

      // 1. Tampilkan Loading Indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 2. Cek apakah sudah pernah mengajukan pengembalian sebelumnya
      final exist = await supabase
          .from('pengembalian')
          .select()
          .eq('id_peminjaman', id)
          .maybeSingle();

      if (exist != null) {
        if (!context.mounted) return;
        Navigator.pop(context); // Tutup loading
        throw "Pengembalian untuk data ini sudah diajukan sebelumnya.";
      }

      // 3. Simpan data ke tabel 'pengembalian'
      await supabase.from('pengembalian').insert({
        'id_peminjaman': id,
        'tanggal_kembali': DateTime.now().toIso8601String(),
        'terlambat_hari': infoDenda['hari'],
        'total_denda': infoDenda['total'],
        'status': 'menunggu', 
      });

      // 4. Update status di tabel 'peminjaman' menjadi 'selesai'
      // Sesuai ENUM Supabase: menunggu, disetujui, ditolak, selesai
      await supabase
          .from('peminjaman')
          .update({'status': 'selesai'})
          .eq('id_peminjaman', id);

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading

      // 5. Berikan feedback sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(infoDenda['hari'] > 0 
            ? "Berhasil dikembalikan dengan denda Rp ${infoDenda['total']}" 
            : "Pengembalian berhasil diajukan. Status: Selesai."),
          backgroundColor: Colors.green,
        ),
      );

      // Kembali ke halaman sebelumnya dan memberi instruksi untuk refresh list
      Navigator.pop(context, true);

    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Tutup loading jika gagal
        _showError(context, e.toString());
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Informasi"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Tutup")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString().toLowerCase() ?? 'menunggu';
    final details = data['detail_peminjaman'] as List? ?? [];
    final infoDenda = _hitungKeterlambatan();

    final isDisetujui = status == 'disetujui';
    final isSelesai = status == 'selesai';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Detail Peminjaman", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(status),
            const SizedBox(height: 25),
            
            // --- KARTU INFO TANGGAL ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _rowInfo("Tanggal Pinjam", _formatDate(data['tanggal_pinjam'])),
                  const Divider(height: 20),
                  _rowInfo("Rencana Kembali", _formatDate(data['tanggal_kembali'])),
                  
                  // Hanya tampil jika peminjaman sudah aktif (disetujui/selesai)
                  if (isDisetujui || isSelesai) ...[
                    const Divider(height: 20),
                    _rowInfo(
                      "Tanggal Tenggat", 
                      _formatDate(data['tanggal_kembali']), 
                      isBold: true,
                      textColor: Colors.blueAccent,
                    ),
                    
                    if (infoDenda['hari'] > 0) ...[
                      const Divider(height: 20),
                      _rowInfo("Keterlambatan", "${infoDenda['hari']} Hari", textColor: Colors.red),
                      _rowInfo("Total Denda", "Rp ${infoDenda['total']}", 
                        isBold: true, textColor: Colors.red),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text("Daftar Alat", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            // Mapping List Alat
            ...details.map((d) => _buildAlatItem(d)).toList(),
            
            const SizedBox(height: 40),

            // Tombol Aksi: Hanya muncul jika barang sudah dipinjam (disetujui) 
            // namun belum dikembalikan (belum selesai)
            if (isDisetujui)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _prosesPengembalian(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4C90),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text("Ajukan Pengembalian", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI SUB-COMPONENTS =================

  Widget _buildAlatItem(Map detail) {
    final alat = detail['alat'] ?? {};
    final String? imageUrl = alat['gambar_alat'];
    final String namaAlat = alat['nama_alat'] ?? 'Nama tidak tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 60, height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaAlat, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Jumlah: ${detail['jumlah']} Unit", 
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60, height: 60,
      color: Colors.grey[100],
      child: const Icon(Icons.inventory_2, color: Colors.blueGrey),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    switch (status) {
      case 'selesai': color = Colors.green; break;
      case 'disetujui': color = Colors.blue; break;
      case 'ditolak': color = Colors.red; break;
      default: color = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        "STATUS: ${status.toUpperCase()}",
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _rowInfo(String label, String val, {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(val, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600, 
          fontSize: 13, 
          color: textColor
        )),
      ],
    );
  }
}