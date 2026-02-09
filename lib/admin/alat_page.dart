import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alat.dart'; // Sesuaikan dengan nama file form alat Anda
import 'kategori_page.dart';  // Import halaman daftar kategori yang baru

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  SupabaseClient get supabase => Supabase.instance.client;

  List<Map<String, dynamic>> dataAlat = [];
  List<Map<String, dynamic>> kategoriList = [];

  bool loading = true;
  String search = "";
  int? selectedKategori; // null = semua

  // ======================================================
  // LOAD DATA
  // ======================================================
  Future<void> loadAll() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final alat = await supabase.from('alat').select();
      final kategori = await supabase.from('kategori').select();

      dataAlat = List<Map<String, dynamic>>.from(alat);
      kategoriList = List<Map<String, dynamic>>.from(kategori);
    } catch (e) {
      debugPrint("Error loading data: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  // ======================================================
  // DELETE DENGAN KONFIRMASI
  // ======================================================
  Future<void> deleteAlat(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Alat?"),
        content: const Text("Data alat ini akan dihapus secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('alat').delete().eq('id_alat', id);
              Navigator.pop(context);
              loadAll();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // KATEGORI BUTTON
  // ======================================================
  Widget kategoriButton(String label, int? id) {
    final selected = selectedKategori == id;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => selectedKategori = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1E4C90) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  
  // CARD ALAT
  Widget alatCard(Map<String, dynamic> alat) {
    final gambar = alat['gambar_alat'] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: gambar != ""
                ? Image.network(
                    gambar,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.inventory),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alat['nama_alat'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text("Stok: ${alat['stok']}", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Tersedia",
                    style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _actionButton("Edit", Colors.blue, Icons.edit, () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FormAlatPage(alat: alat)),
                      );
                      if (result == true) loadAll();
                    }),
                    const SizedBox(width: 6),
                    _actionButton("Hapus", Colors.red, Icons.delete, () => deleteAlat(alat['id_alat'])),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = dataAlat.where((e) {
      final cocokSearch = e['nama_alat'].toString().toLowerCase().contains(search.toLowerCase());
      final cocokKategori = selectedKategori == null || e['id_kategori'] == selectedKategori;
      return cocokSearch && cocokKategori;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _fabBox(Icons.add, "Tambah", () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormAlatPage()),
            );
            if (result == true) loadAll();
          }),
          const SizedBox(height: 10),
          _fabBox(Icons.grid_view, "Kategori", () async {
            // NAVIGASI KE HALAMAN KATEGORI
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KategoriPage()),
            );
            // Refresh data setelah kembali dari halaman kategori
            loadAll();
          }),
        ],
      ),
      body: Column(
        children: [
          // HEADER SEARCH
          Container(
            padding: const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 25),
            decoration: const BoxDecoration(
              color: Color(0xFF1E4C90),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: "Cari alat pinjaman...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LIST KATEGORI HORIZONTAL
          Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  kategoriButton("Semua", null),
                  ...kategoriList.map((k) => kategoriButton(k['nama_kategori'], k['id_kategori'])),
                ],
              ),
            ),
          ),

          // LIST ALAT
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text("Data alat tidak ditemukan"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => alatCard(filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _fabBox(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}