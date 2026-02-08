import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HalamanRiwayat extends StatefulWidget {
  const HalamanRiwayat({super.key});

  @override
  State<HalamanRiwayat> createState() => _HalamanRiwayatState();
}

class _HalamanRiwayatState extends State<HalamanRiwayat> {
  final supabase = Supabase.instance.client;
  String _searchQuery = "";
  String _selectedFilter = "Semua";

  final List<String> _filters = ["Semua", "Dipinjam", "Kembali", "Terlambat", "Rusak"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER BIRU ---
          Container(
            padding: const EdgeInsets.only(top: 50, left: 10, right: 10, bottom: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4C90),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text("Riwayat", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Cari nama atau alat...",
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- TAB FILTER (Chip) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: _filters.map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E4C90),
                    // --- BAGIAN INI UNTUK MENGHILANGKAN CENTANG ---
                    showCheckmark: false, 
                    // ----------------------------------------------
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black, 
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    onSelected: (bool selected) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // --- DAFTAR RIWAYAT ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('peminjaman').stream(primaryKey: ['id_peminjaman']).order('tanggal_pinjam'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final listData = snapshot.data!.where((item) {
                  bool matchesFilter = _selectedFilter == "Semua" || item['status'] == _selectedFilter;
                  return matchesFilter;
                }).toList();

                if (listData.isEmpty) return const Center(child: Text("Riwayat tidak ditemukan"));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: listData.length,
                  itemBuilder: (context, index) {
                    final item = listData[index];
                    return _buildRiwayatCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    Color statusColor;
    switch (item['status'].toString().toLowerCase()) {
      case 'kembali': statusColor = Colors.green; break;
      case 'terlambat': statusColor = Colors.red; break;
      case 'rusak': statusColor = Colors.purple; break;
      default: statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.laptop, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nama Peminjam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text("Nama Alat / Perangkat", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${item['tanggal_pinjam']} - ${item['tanggal_kembali'] ?? '...'}", 
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(item['status'], 
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _confirmDelete(item['id_peminjaman']),
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              label: const Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
            SizedBox(height: 10),
            Text("Hapus Riwayat?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Data riwayat akan dihapus permanen.", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('peminjaman').delete().eq('id_peminjaman', id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}