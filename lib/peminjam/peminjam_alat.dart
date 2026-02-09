import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlatPeminjamPage extends StatefulWidget {
  const AlatPeminjamPage({super.key});

  @override
  State<AlatPeminjamPage> createState() => _AlatPeminjamPageState();
}

class _AlatPeminjamPageState extends State<AlatPeminjamPage> {
  final supabase = Supabase.instance.client;
  
  // Gunakan id 0 untuk kategori "Semua"
  int selectedKategoriId = 0; 
  String selectedKategoriName = "Semua";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          
          // Tab Kategori dengan tombol "Semua"
          _buildCategoryTabs(),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Alat kategori $selectedKategoriName belum tersedia.", 
                             style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return _buildAlatCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Logika Query: Jika ID 0, jangan filter berdasarkan id_kategori
  Stream<List<Map<String, dynamic>>> _getFilteredStream() {
    var query = supabase.from('alat').stream(primaryKey: ['id_alat']);
    
    if (selectedKategoriId != 0) {
      return query.eq('id_kategori', selectedKategoriId);
    }
    
    return query; // Mengembalikan semua data jika id_kategori adalah 0
  }

  Widget _buildCategoryTabs() {
    // Tambahkan "Semua" ke dalam daftar categories
    final categories = [
      {'id': 0, 'name': 'Semua'},
      {'id': 1, 'name': 'Laptop'},
      {'id': 2, 'name': 'Proyektor'},
      {'id': 3, 'name': 'Kamera'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories.map((cat) {
          bool isSelected = selectedKategoriId == cat['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedKategoriId = cat['id'] as int;
                selectedKategoriName = cat['name'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5BA2E1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cat['name'].toString(), 
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Fungsi buildHeader, buildAlatCard, dan badgeKondisi tetap sama seperti sebelumnya
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hallo, Peminjam", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: "Cari alat pinjamanmu...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlatCard(Map<String, dynamic> alat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              alat['gambar_alat'] ?? '', 
              width: 80, height: 60, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat['nama_alat'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Stok: ${alat['stok']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                _badgeKondisi(alat['kondisi'] ?? 'tersedia'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4C90),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text("Detail", style: TextStyle(color: Colors.white, fontSize: 11)),
          )
        ],
      ),
    );
  }

  Widget _badgeKondisi(String kondisi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: kondisi == "tersedia" ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(5)
      ),
      child: Text(
        kondisi.toUpperCase(), 
        style: TextStyle(
          color: kondisi == "tersedia" ? Colors.green : Colors.orange, 
          fontSize: 9, fontWeight: FontWeight.bold
        )
      ),
    );
  }
}