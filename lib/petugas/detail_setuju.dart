import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DetailSetujuPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailSetujuPage({super.key, required this.item});

  @override
  State<DetailSetujuPage> createState() => _DetailSetujuPageState();
}

class _DetailSetujuPageState extends State<DetailSetujuPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Helper data bersarang
    final user = widget.item['users'] as Map<String, dynamic>? ?? {};
    final List details = widget.item['detail_peminjaman'] as List? ?? [];
    final detail = details.isNotEmpty ? details.first as Map<String, dynamic> : {};
    final alat = detail['alat'] as Map<String, dynamic>? ?? {};
    
    final statusSekarang = widget.item['status']?.toString().toLowerCase() ?? 'menunggu';

    // Formatter Tanggal
    String formatTanggal(String? dateStr) {
      if (dateStr == null) return '-';
      try {
        return DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(dateStr));
      } catch (e) {
        return dateStr;
      }
    }

    final tanggalPinjam = formatTanggal(widget.item['tanggal_pinjam']);
    final tanggalKembali = formatTanggal(widget.item['tanggal_kembali']);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail Persetujuan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBorrowerHeader(user),
                const SizedBox(height: 16),
                _buildSectionTitle('Informasi Alat'),
                _buildAlatCard(alat, detail),
                const SizedBox(height: 16),
                _buildSectionTitle('Waktu Peminjaman'),
                _buildTimelineCard(tanggalPinjam, tanggalKembali),
                const SizedBox(height: 32),
                
                // AREA VALIDASI (TOMBOL ATAU BOX STATUS)
                _buildActionArea(statusSekarang),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildBorrowerHeader(Map user) {
    String initial = user['nama']?.toString().substring(0, 1).toUpperCase() ?? 'U';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF1E4C90).withOpacity(0.1),
            child: Text(initial,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E4C90))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Peminjam', style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(user['nama'] ?? 'Tanpa Nama',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user['email'] ?? '-',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildAlatCard(Map alat, Map detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: alat['gambar_alat'] != null
                    ? Image.network(
                        alat['gambar_alat'],
                        width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                      )
                    : _buildPlaceholderIcon(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alat['nama_alat'] ?? '-',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Jumlah: ${detail['jumlah'] ?? 0} unit',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(String tglPinjam, String tglKembali) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoRow('Tanggal Ambil', tglPinjam, Icons.calendar_today_outlined),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _buildInfoRow('Estimasi Kembali', tglKembali, Icons.history_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(String status) {
    if (status == 'menunggu') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _showConfirmDialog('ditolak'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('TOLAK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _showConfirmDialog('disetujui'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: const Color(0xFF1E4C90),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('SETUJUI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // TAMPILAN VALIDASI SETELAH PROSES (DITOLAK/DISETUJUI)
    bool isApprove = status == 'disetujui';
    Color themeColor = isApprove ? Colors.green : Colors.red;
    IconData statusIcon = isApprove ? Icons.check_circle : Icons.cancel;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Ikon Bulat Solid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(statusIcon, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Teks Status
            Text(
              'Peminjaman ini telah ${status.toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 8),
            // Keterangan
            Text(
              isApprove 
                ? 'Silahkan ambil alat sesuai jadwal yang tertera.' 
                : 'Maaf, pengajuan ditolak karena alasan tertentu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 70, height: 70, color: Colors.grey.shade100,
      child: const Icon(Icons.inventory_2_outlined, size: 30, color: Colors.grey),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF1E4C90)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF1E4C90)),
                SizedBox(height: 20),
                Text('Menyimpan Perubahan...', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  void _showConfirmDialog(String newStatus) {
    final bool isApprove = newStatus == 'disetujui';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Setujui Peminjaman?' : 'Tolak Peminjaman?'),
        content: Text('Apakah Anda yakin ingin mengubah status menjadi ${newStatus.toLowerCase()}?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(newStatus);
            },
            child: const Text('YA, PROSES', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('peminjaman')
          .update({'status': newStatus.toLowerCase()})
          .eq('id_peminjaman', widget.item['id_peminjaman'])
          .select();

      if (response.isEmpty) throw 'Gagal memperbarui data.';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil diperbarui menjadi $newStatus'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}