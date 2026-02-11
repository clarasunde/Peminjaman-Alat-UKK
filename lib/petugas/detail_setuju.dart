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
  
  DateTime? _selectedTenggat;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi tenggat dari database
    if (widget.item['tanggal_kembali'] != null) {
      _selectedTenggat = DateTime.parse(widget.item['tanggal_kembali'].toString());
    } else {
      _selectedTenggat = DateTime.now().add(const Duration(days: 1));
    }
  }

  Future<void> _pickTenggatDate(BuildContext context) async {
    // Validasi: Jika sudah bukan 'menunggu', jangan izinkan buka picker
    if (widget.item['status'] != 'menunggu') return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTenggat ?? DateTime.now(),
      firstDate: DateTime.now(), 
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedTenggat = picked;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final idPinjam = widget.item['id_peminjaman'];

      await supabase.from('peminjaman').update({
        'status': status,
        'tanggal_kembali': _selectedTenggat?.toIso8601String(), 
      }).eq('id_peminjaman', idPinjam);

      if (mounted) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil: Status diubah menjadi $status"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.item['users'] ?? {};
    final List details = widget.item['detail_peminjaman'] ?? [];
    final String status = widget.item['status']?.toString().toLowerCase() ?? 'menunggu';
    
    // VALIDASI: Cek apakah status masih 'menunggu'
    final bool isWaiting = status == 'menunggu';

    String formatDate(dynamic date) {
      if (date == null) return "-";
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date.toString()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        title: const Text("Detail Persetujuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(status), // Banner Status
                const SizedBox(height: 20),
                _buildProfileCard(user['nama'], user['email']),
                const SizedBox(height: 25),
                const Text("Daftar Alat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...details.map((d) => _buildAlatTile(d)).toList(),
                const SizedBox(height: 25),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildReadOnlyInfo("Tanggal Pinjam", formatDate(widget.item['tanggal_pinjam'])),
                      const Divider(height: 25),
                      _buildReadOnlyInfo("Rencana Kembali (User)", formatDate(widget.item['tanggal_kembali'])),
                      const Divider(height: 25),
                      
                      // Bagian Atur Tenggat
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(isWaiting ? "Atur Tenggat Pengembalian" : "Tenggat Pengembalian Tetap", 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      ),
                      const SizedBox(height: 10),
                      _buildTenggatSelector(isWaiting),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                _buildActionButtons(isWaiting), // Tombol dinamis
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildStatusBanner(String status) {
    Color color = status == 'disetujui' ? Colors.green : status == 'ditolak' ? Colors.red : Colors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "STATUS: ${status.toUpperCase()}",
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTenggatSelector(bool clickable) {
    return InkWell(
      onTap: clickable ? () => _pickTenggatDate(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: clickable ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: clickable ? const Color(0xFF1E4C90).withOpacity(0.3) : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedTenggat != null ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedTenggat!) : "Belum Diatur",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: clickable ? const Color(0xFF1E4C90) : Colors.black54
              ),
            ),
            if (clickable) const Icon(Icons.calendar_month, color: Color(0xFF1E4C90)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isWaiting) {
    if (!isWaiting) {
      // Jika sudah disetujui/ditolak, hanya tampilkan tombol TUTUP
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup Detail", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    // Jika masih 'menunggu', tampilkan Setujui & Tolak
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => _updateStatus('ditolak'),
            child: const Text("Tolak Pinjaman", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4C90),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => _updateStatus('disetujui'),
            child: const Text("Setujui & Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ... (Widget _buildProfileCard, _buildReadOnlyInfo, dan _buildAlatTile tetap sama)
  Widget _buildProfileCard(String? nama, String? email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, color: Color(0xFF1E4C90))),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(email ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildAlatTile(Map<String, dynamic> detail) {
    final alat = detail['alat'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: alat['gambar_alat'] != null 
            ? Image.network(alat['gambar_alat'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
            : const Icon(Icons.inventory_2, size: 30),
        ),
        title: Text(alat['nama_alat'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text("${detail['jumlah']} Unit", style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
      ),
    );
  }
}