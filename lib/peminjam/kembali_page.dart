import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class KembaliPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const KembaliPage({super.key, this.userData});

  @override
  State<KembaliPage> createState() => _KembaliPageState();
}

class _KembaliPageState extends State<KembaliPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _riwayatList = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayatKembali();
  }

  // Fungsi format tanggal agar rapi
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _fetchRiwayatKembali() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      // PERBAIKAN QUERY: Kita ambil dari tabel pengembalian
      // Pastikan relasi di Supabase sudah benar
      final response = await supabase
          .from('pengembalian')
          .select('''
            *,
            peminjaman!inner (
              id_user,
              status,
              detail_peminjaman (
                jumlah,
                alat (nama_alat, gambar_alat)
              )
            )
          ''')
          .eq('peminjaman.id_user', userId as Object)
          .order('tanggal_kembali', ascending: false);

      setState(() {
        _riwayatList = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetch riwayat: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchRiwayatKembali,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _riwayatList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _riwayatList.length,
                          itemBuilder: (context, index) {
                            return _buildCardRiwayat(_riwayatList[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Belum ada riwayat pengembalian", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final String userEmail = widget.userData?['email'] ?? 
                             supabase.auth.currentUser?.email ?? 'peminjam@gmail.com';
    final String userName = userEmail.split('@')[0];

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30)
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25, 
            backgroundColor: Colors.white, 
            child: Icon(Icons.person, size: 30, color: Color(0xFF1E4C90))
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hallo, ${userName[0].toUpperCase()}${userName.substring(1)}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardRiwayat(Map<String, dynamic> data) {
    final peminjaman = data['peminjaman'];
    if (peminjaman == null) return const SizedBox.shrink();

    final details = peminjaman['detail_peminjaman'] as List;
    final alatData = details.isNotEmpty ? details[0]['alat'] : null;
    
    // Logika Status Pengembalian (Menunggu/Disetujui)
    final String statusKembali = data['status_pengembalian'] ?? 'menunggu';
    bool isSelesai = statusKembali.toLowerCase() == 'disetujui';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60, height: 60,
                  color: Colors.grey[200],
                  child: alatData != null && alatData['gambar_alat'] != null
                      ? Image.network(alatData['gambar_alat'], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                      : const Icon(Icons.inventory_2, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alatData?['nama_alat'] ?? "Peminjaman Alat", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Dikembalikan pada:", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(_formatDate(data['tanggal_kembali']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Badge Status (Menunggu / Disetujui)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelesai ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusKembali.toUpperCase(),
                  style: TextStyle(
                    color: isSelesai ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ${details.length} Alat", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              TextButton(
                onPressed: () {
                  // Navigasi ke Detail Pengembalian jika diperlukan
                },
                child: const Text("Lihat Detail", style: TextStyle(fontSize: 12, color: Color(0xFF1E4C90), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }
}