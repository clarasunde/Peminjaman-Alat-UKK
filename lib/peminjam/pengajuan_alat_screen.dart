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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // List Barang Ringkasan dengan Gambar
                ...widget.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildImageWidget(item),
                    title: Text(
                      item['nama_alat'] ?? 'Nama Alat',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      "Kondisi awal baik",
                      style: TextStyle(fontSize: 13),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E4C90).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${item['jumlah_pinjam']} Unit",
                        style: const TextStyle(
                          color: Color(0xFF1E4C90),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )),
                const Divider(height: 30, thickness: 1),
                
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4C90),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _kirimPengajuan,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "KIRIM PENGAJUAN", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Widget untuk menampilkan gambar dari Supabase atau icon fallback
  Widget _buildImageWidget(Map<String, dynamic> item) {
    final String? imageUrl = item['gambar_alat'];
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Jika gambar gagal load, tampilkan icon
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1E4C90).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2, 
                color: Color(0xFF1E4C90), 
                size: 35,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            // Tampilkan loading indicator saat gambar sedang dimuat
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1E4C90),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Jika tidak ada URL gambar, tampilkan icon
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1E4C90).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.inventory_2, 
          color: Color(0xFF1E4C90), 
          size: 35,
        ),
      );
    }
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