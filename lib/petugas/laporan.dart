import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'laporan_pengembalian.dart';
import 'laporan_peminjam.dart'; // Pastikan nama file ini benar (peminjaman vs peminjam)

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeaderPetugas(),
            const SizedBox(height: 25),
            
            // KARTU PEMINJAM
            _buildLaporanCard(
              title: "Kartu Peminjam",
              subtitle: "Laporan daftar peminjam perangkat",
              onTap: () {
                print("Navigasi ke Laporan Peminjaman");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LaporanPeminjamanPage()),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // KARTU KEMBALIAN
            _buildLaporanCard(
              title: "Kartu Kembalian",
              subtitle: "Laporan daftar perangkat dikembalikan",
              onTap: () {
                print("Navigasi ke Laporan Pengembalian");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LaporanPengembalianPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPetugas() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E4C90),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hallo Petugas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(supabase.auth.currentUser?.email ?? "petugas1@gmail.com", 
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? imagePath, // Dibuat opsional agar tidak error jika tidak diisi
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.assignment, size: 40, color: Color(0xFF1E4C90)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.print, size: 18, color: Colors.white),
              label: const Text("Cetak Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}