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

  // Filter disesuaikan dengan status di Supabase
  final List<String> _filters = ["Semua", "Menunggu", "Disetujui", "Ditolak", "Selesai"];

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
                    Icon(Icons.history_edu, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Cari Nama Peminjam...",
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

          // --- FILTER CHIPS (Tanpa Ikon Centang) ---
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
                      showCheckmark: false, // Menghilangkan ikon centang di dalam kotak
                      selectedColor: const Color(0xFF1E4C90),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // --- LIST DATA ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_peminjaman'])
                  .order('tanggal_pinjam', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final listData = snapshot.data!.where((item) {
                  final statusDb = item['status'].toString().toLowerCase();
                  final filterLower = _selectedFilter.toLowerCase();
                  
                  bool matchesFilter = _selectedFilter == "Semua" || statusDb == filterLower;
                  bool matchesSearch = item['id_peminjaman'].toString().contains(_searchQuery);
                  
                  return matchesFilter && matchesSearch;
                }).toList();

                if (listData.isEmpty) return const Center(child: Text("Tidak ada riwayat"));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
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
                      FutureBuilder(
                        future: supabase.from('users').select('nama').eq('id_user', item['id_user']).single(),
                        builder: (context, res) {
                          if (res.hasData) {
                            return Text(res.data!['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                          }
                          return const Text("Memuat...", style: TextStyle(color: Colors.grey));
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
                    Text(
                      item['tanggal_pinjam']?.toString().substring(0, 10) ?? "-", 
                      style: const TextStyle(fontSize: 12)
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _confirmDelete(item),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    status = status.toLowerCase();
    Color color = Colors.grey;
    
    // Penyesuaian warna berdasarkan status yang diminta
    if (status.contains('menunggu')) color = Colors.orange;
    if (status.contains('disetujui')) color = Colors.green;
    if (status.contains('ditolak')) color = Colors.red;
    if (status.contains('selesai')) color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text("Data ini akan dihapus permanen dari riwayat peminjaman."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await supabase.from('peminjaman').delete().eq('id_peminjaman', item['id_peminjaman']);
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                debugPrint(e.toString());
              }
            }, 
            child: const Text("Hapus", style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );
  }
}