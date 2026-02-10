import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PinjamPage extends StatefulWidget {
  // 1. Terima data user dari halaman induk
  final Map<String, dynamic>? userData;

  const PinjamPage({super.key, this.userData});

  @override
  State<PinjamPage> createState() => _PinjamPageState();
}

class _PinjamPageState extends State<PinjamPage> {
  final supabase = Supabase.instance.client;

  // Mendapatkan ID user yang sedang login untuk filter data
  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header Dinamis
          _buildHeader(),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Realtime stream data peminjaman milik user yang sedang login
              stream: supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_peminjaman'])
                  .eq('id_user', currentUserId)
                  .order('tanggal_pinjam', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final dataPeminjaman = snapshot.data ?? [];

                if (dataPeminjaman.isEmpty) {
                  return const Center(child: Text("Belum ada riwayat pengajuan."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: dataPeminjaman.length,
                  itemBuilder: (context, index) {
                    final item = dataPeminjaman[index];
                    return _buildPinjamCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Ambil email dari userData, jika tidak ada ambil dari auth, jika tidak ada pake default
    final String userEmail = widget.userData?['email'] ?? 
                             supabase.auth.currentUser?.email ?? 
                             'peminjam@gmail.com';

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
              const Text(
                "Hallo Peminjam", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              Text(
                userEmail, 
                style: const TextStyle(color: Colors.white70, fontSize: 13)
              ),
              const Row(
                children: [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                  SizedBox(width: 5),
                  Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinjamCard(Map<String, dynamic> data) {
    String status = data['status'] ?? 'menunggu'; 
    bool isApproved = status == 'disetujui';

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
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.inventory_2, color: Colors.grey),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detail Pengajuan", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "${data['tanggal_pinjam']} s/d ${data['tanggal_kembali']}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 11)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isApproved ? Colors.green : Colors.orange,
                    fontSize: 9, fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Riwayat Pengajuan", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ElevatedButton(
                onPressed: () => _showDetailModal(data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4C90),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text("Lihat Detail", style: TextStyle(color: Colors.white, fontSize: 11)),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailModal(Map<String, dynamic> data) {
    bool isApproved = data['status'] == 'disetujui';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(isApproved ? "Pengajuan Disetujui" : "Menunggu Persetujuan", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              isApproved 
                ? "Pengajuan kamu sudah disetujui petugas. Silakan ambil alat di gudang." 
                : "Petugas sedang memproses pengajuanmu. Harap tunggu konfirmasi.",
              style: const TextStyle(color: Colors.grey, fontSize: 13)
            ),
            const Divider(height: 30),
            _infoRow("Tanggal Pinjam", data['tanggal_pinjam'] ?? '-'),
            _infoRow("Tanggal Kembali", data['tanggal_kembali'] ?? '-'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4C90),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Tutup", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}