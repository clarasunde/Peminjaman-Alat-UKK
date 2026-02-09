import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanAdminLog extends StatefulWidget {
  const HalamanAdminLog({super.key});

  @override
  State<HalamanAdminLog> createState() => _HalamanAdminLogState();
}

class _HalamanAdminLogState extends State<HalamanAdminLog> {
  final supabase = Supabase.instance.client;
  String _searchQuery = "";
  String _selectedFilter = "Semua";

  final List<String> _filters = ["Semua", "Dipinjam", "Kembali", "Terlambat", "Rusak"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // --- HEADER ADMIN ---
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E4C90), Color(0xFF13366D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Panel Audit Admin", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(Icons.admin_panel_settings, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Cari Peminjam...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1E4C90)),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // --- FILTER CHIPS ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1E4C90),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // --- LIST DATA ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Tips: Stream hanya bisa satu tabel. 
              // Untuk nama user, kita akan gunakan widget FutureBuilder di dalam Card atau join logic.
              stream: supabase.from('peminjaman').stream(primaryKey: ['id_peminjaman'])
                  .order('tanggal_pinjam'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final listData = snapshot.data!.where((item) {
                  bool matchesFilter = _selectedFilter == "Semua" || item['status'] == _selectedFilter;
                  return matchesFilter;
                }).toList();

                if (listData.isEmpty) return const Center(child: Text("Tidak ada riwayat"));

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: listData.length,
                  itemBuilder: (context, index) => _buildAdminCard(listData[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
     margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8EEF7),
                  child: Icon(Icons.person, color: Color(0xFF1E4C90)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menggunakan FutureBuilder untuk mengambil Nama User berdasarkan id_user
                      FutureBuilder(
                        future: supabase.from('users').select('nama_lengkap').eq('id_user', item['id_user']).single(),
                        builder: (context, res) {
                          String nama = res.hasData ? res.data!['nama_lengkap'] : "Memuat...";
                          return Text(nama, style: const TextStyle(fontWeight: FontWeight.bold));
                        }
                      ),
                      Text("ID Pinjam: #${item['id_peminjaman']}", 
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                _buildStatusBadge(item['status']),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(item['tanggal_pinjam'].toString().substring(0, 10), style: const TextStyle(fontSize: 12)),
                  ],
                ),
                // Tombol Hapus dengan Audit Log
                IconButton(
                  onPressed: () => _confirmDelete(item),
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Kembali') color = Colors.green;
    if (status == 'Terlambat') color = Colors.red;
    if (status == 'Rusak') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Audit"),
        content: const Text("Menghapus riwayat ini akan dicatat dalam Log Aktivitas Admin. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // 1. Catat ke Log Aktivitas secara manual sebelum hapus (Atau via Database Trigger)
                await supabase.from('log_aktivitas').insert({
                  'id_user': supabase.auth.currentUser!.id,
                  'aksi': 'Hapus Riwayat',
                  'keterangan': 'Admin menghapus peminjaman ID #${item['id_peminjaman']}',
                });

                // 2. Hapus data
                await supabase.from('peminjaman').delete().eq('id_peminjaman', item['id_peminjaman']);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Riwayat berhasil dihapus & dicatat log")));
                }
              } catch (e) {
                print(e);
              }
            }, 
            child: const Text("Hapus & Catat Log", style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );
  }
}