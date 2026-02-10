import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KembaliPage extends StatefulWidget {
  // 1. Terima data user agar header dinamis
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

  Future<void> _fetchRiwayatKembali() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      // Mengambil data pengembalian milik user yang sedang login
      final response = await supabase
          .from('pengembalian')
          .select('''
            id_pengembalian,
            tanggal_kembali,
            peminjaman (
              id_user,
              status,
              detail_peminjaman (
                jumlah,
                alat (nama_alat, gambar_alat)
              )
            )
          ''')
          .eq('peminjaman.id_user', userId as Object) // Filter berdasarkan user login
          .order('tanggal_kembali', ascending: false);

      setState(() {
        _riwayatList = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetch: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background sedikit abu agar card terlihat
      body: Column(
        children: [
          // Header Dinamis
          _buildHeader(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _riwayatList.isEmpty
                    ? const Center(child: Text("Belum ada riwayat pengembalian"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayatList.length,
                        itemBuilder: (context, index) {
                          final item = _riwayatList[index];
                          return _buildCardRiwayat(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Ambil data email dan nama dari userData atau auth
    final String userEmail = widget.userData?['email'] ?? 
                             supabase.auth.currentUser?.email ?? 
                             'peminjam@gmail.com';
    
    // Ambil nama depan dari email untuk sapaan
    final String userName = userEmail.split('@')[0];

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4E8E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30)
        )
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35, color: Color(0xFF1E4E8E)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hallo, ${userName[0].toUpperCase()}${userName.substring(1)}", 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(userEmail, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                  SizedBox(width: 5),
                  Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCardRiwayat(Map<String, dynamic> data) {
    final peminjaman = data['peminjaman'];
    
    // Safety check jika data detail kosong
    if (peminjaman == null || peminjaman['detail_peminjaman'].isEmpty) {
      return const SizedBox.shrink();
    }

    final detail = peminjaman['detail_peminjaman'][0];
    final String status = peminjaman['status'].toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Gambar Alat
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  detail['alat']['gambar_alat'] ?? '',
                  width: 60, height: 60, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                    Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.inventory)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail['alat']['nama_alat'] ?? 'Alat tidak diketahui', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Dikembalikan pada:", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    Text(data['tanggal_kembali'] ?? '-', style: const TextStyle(color: Colors.black87, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: ${peminjaman['detail_peminjaman'].length} alat", 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              
              // Badge Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'selesai' || status.toLowerCase() == 'disetujui' 
                      ? Colors.green[50] 
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status.toLowerCase() == 'selesai' || status.toLowerCase() == 'disetujui' 
                        ? Colors.green 
                        : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}