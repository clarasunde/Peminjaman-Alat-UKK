import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kategori.dart'; 

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final supabase = Supabase.instance.client;

  final Stream<List<Map<String, dynamic>>> _kategoriStream =
      Supabase.instance.client
          .from('kategori')
          .stream(primaryKey: ['id_kategori'])
          .order('nama_kategori');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Background sedikit abu agar shadow terlihat
      appBar: AppBar(
        title: const Text("Daftar Kategori", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: const Color(0xFF1E4C90),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header: Search & Tombol Tambah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Input Cari (175 x 39)
                SizedBox(
                  width: 175,
                  height: 39,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari kategori alat...",
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black),
                      filled: true,
                      fillColor: const Color(0xFFD9D9D9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Tambah (182 x 39)
                SizedBox(
                  width: 182,
                  height: 39,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FormKategori()),
                    ),
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    label: const Text("Tambah kategori", 
                      style: TextStyle(fontSize: 12, color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A86E8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List Kategori dengan Shadow sesuai Desain
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _kategoriStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final listKategori = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: listKategori.length,
                  itemBuilder: (context, index) {
                    final item = listKategori[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // Shadow halus
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        title: Text(
                          item['nama_kategori'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Edit
                            _buildActionButton("Edit", Icons.edit, const Color(0xFFE8EFFF), const Color(0xFF1E4C90), () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FormKategori(kategori: item)));
                            }),
                            const SizedBox(width: 8),
                            // Tombol Hapus
                            _buildActionButton("Hapus", Icons.delete, const Color(0xFFFFEAEA), Colors.red, () {
                              _konfirmasiHapus(context, item['id_kategori']);
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat tombol aksi Edit/Hapus sesuai gambar
  Widget _buildActionButton(String label, IconData icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Kategori?"),
        content: const Text("Data ini akan dihapus secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await supabase.from('kategori').delete().eq('id_kategori', id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}