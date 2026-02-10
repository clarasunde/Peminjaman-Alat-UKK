import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_alat_screen.dart'; // Import untuk akses keranjangGlobal

class PengajuanAlatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const PengajuanAlatScreen({super.key, required this.items});

  @override
  State<PengajuanAlatScreen> createState() => _PengajuanAlatScreenState();
}

class _PengajuanAlatScreenState extends State<PengajuanAlatScreen> {
  DateTime? tanggalPinjam;
  DateTime? tanggalKembali;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  // Fungsi Pilih Tanggal
  Future<void> _selectDate(BuildContext context, bool isPinjam) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPinjam) {
          tanggalPinjam = picked;
        } else {
          tanggalKembali = picked;
        }
      });
    }
  }

  // Fungsi Kirim ke Petugas (Simpan ke Supabase)
  Future<void> _kirimPengajuan() async {
    if (tanggalPinjam == null || tanggalKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tanggal pinjam dan kembali!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      
      // 1. Insert ke tabel peminjaman
      final resPeminjaman = await supabase.from('peminjaman').insert({
        'id_user': user!.id,
        'tanggal_pinjam': tanggalPinjam!.toIso8601String(),
        'tanggal_kembali': tanggalKembali!.toIso8601String(),
        'status': 'menunggu', // Status awal sesuai ERD
      }).select().single();

      final idPeminjaman = resPeminjaman['id_peminjaman'];

      // 2. Insert ke tabel detail_peminjaman
      final List<Map<String, dynamic>> details = widget.items.map((item) {
        return {
          'id_peminjaman': idPeminjaman,
          'id_alat': item['id_alat'],
          'jumlah': item['jumlah_pinjam'],
        };
      }).toList();

      await supabase.from('detail_peminjaman').insert(details);

      // 3. Bersihkan keranjang
      keranjangGlobal.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pengajuan berhasil dikirim!")),
        );
        // Kembali ke Home/Beranda dan bersihkan stack navigasi
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengajuan Alat", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // List Barang Ringkasan
                ...widget.items.map((item) => ListTile(
                  leading: const Icon(Icons.inventory_2, color: Color(0xFF1E4C90)),
                  title: Text(item['nama_alat']),
                  subtitle: const Text("Kondisi awal baik"),
                  trailing: Text("${item['jumlah_pinjam']} Unit"),
                )),
                const Divider(),
                
                // Input Tanggal Pinjam
                _buildDateTile("Tanggal Pinjam", tanggalPinjam, true),
                const SizedBox(height: 10),
                // Input Tanggal Kembali
                _buildDateTile("Tanggal Kembali", tanggalKembali, false),
              ],
            ),
          ),
          
          // Tombol Kirim
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4C90)),
                onPressed: isLoading ? null : _kirimPengajuan,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("KIRIM PENGAJUAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, bool isPinjam) {
    return InkWell(
      onTap: () => _selectDate(context, isPinjam),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(date == null ? "Pilih Tanggal" : DateFormat('EEEE, d MMMM yyyy').format(date)),
              ],
            ),
            const Icon(Icons.calendar_month, color: Color(0xFF1E4C90)),
          ],
        ),
      ),
    );
  }
}