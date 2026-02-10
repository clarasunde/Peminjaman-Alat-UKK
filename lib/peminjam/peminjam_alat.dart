import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_alat_screen.dart';
import 'keranjang_screen.dart';
import '../peminjam/notifikasi.dart';

class AlatPeminjamPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AlatPeminjamPage({super.key, this.userData});

  @override
  State<AlatPeminjamPage> createState() => _AlatPeminjamPageState();
}

class _AlatPeminjamPageState extends State<AlatPeminjamPage> {
  final supabase = Supabase.instance.client;

  int jumlahNotif = 0;

  // ================= SEARCH BAR (BARU)
  String searchText = '';
  final TextEditingController searchController = TextEditingController();

  // ================= FILTER KATEGORI
  int selectedKategoriId = 0;

  final kategoriList = [
    {'id': 0, 'name': 'Semua'},
    {'id': 1, 'name': 'Laptop'},
    {'id': 2, 'name': 'Proyektor'},
    {'id': 3, 'name': 'Kamera'},
  ];

  @override
  void initState() {
    super.initState();
    getNotifCount();
  }

  // ================= NOTIF =================
  Future<void> getNotifCount() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final res = await supabase
        .from('notifikasi')
        .select()
        .eq('id_user', userId)
        .eq('is_read', false);

    setState(() => jumlahNotif = res.length);
  }

  // ================= STREAM + FILTER =================
  Stream<List<Map<String, dynamic>>> _getStream() {
    var query = supabase.from('alat').stream(primaryKey: ['id_alat']);

    if (selectedKategoriId != 0) {
      return query.eq('id_kategori', selectedKategoriId);
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail =
        widget.userData?['email'] ?? supabase.auth.currentUser?.email ?? '';
    final userName = widget.userData?['nama'] ?? 'Peminjam';

    return Scaffold(
      backgroundColor: Colors.white,

      // ================= FAB =================
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xFF1E4C90),
            child: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KeranjangScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),

          if (keranjangGlobal.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: Colors.red,
                child: Text(
                  "${keranjangGlobal.length}",
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            )
        ],
      ),

      body: Column(
        children: [
          // ================= HEADER + SEARCH =================
          CustomHeader(
            nama: userName,
            email: userEmail,
            jumlahNotif: jumlahNotif,
            controller: searchController,
            onSearch: (value) {
              setState(() => searchText = value);
            },
            onNotifTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotifikasiPage()),
              );
            },
          ),

          // ================= KATEGORI TAB =================
          _buildCategoryTabs(),

          // ================= LIST =================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getStream(),
              builder: (context, snapshot) {
                final raw = snapshot.data ?? [];

                // 🔥 FILTER SEARCH LOKAL
                final data = raw.where((item) {
                  final nama =
                      (item['nama_alat'] ?? '').toString().toLowerCase();
                  return nama.contains(searchText.toLowerCase());
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: data.length,
                  itemBuilder: (_, i) => _buildAlatCard(data[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY =================
  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: kategoriList.map((cat) {
          final isSelected = selectedKategoriId == cat['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedKategoriId = cat['id'] as int;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E4C90)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cat['name'].toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= CARD =================
  Widget _buildAlatCard(Map<String, dynamic> alat) {
    final imageUrl = alat['gambar_alat'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 65,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat['nama_alat'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Stok: ${alat['stok']}"),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailAlatScreen(alat: alat),
                ),
              );
            },
            child: const Text("Detail"),
          )
        ],
      ),
    );
  }
}








// ==================================================
// HEADER + SEARCH BAR (UPDATE)
// ==================================================
class CustomHeader extends StatelessWidget {
  final String nama;
  final String email;
  final int jumlahNotif;
  final VoidCallback onNotifTap;
  final Function(String) onSearch;
  final TextEditingController controller;

  const CustomHeader({
    super.key,
    required this.nama,
    required this.email,
    required this.jumlahNotif,
    required this.onNotifTap,
    required this.onSearch,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hallo $nama",
                      style: const TextStyle(color: Colors.white)),
                  Text(email,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
              IconButton(
                icon:
                    const Icon(Icons.notifications, color: Colors.white),
                onPressed: onNotifTap,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 🔥 TEXT BARU
          const Text(
            "Pinjam alat apa hari ini?",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // 🔥 SEARCH BAR
          TextField(
            controller: controller,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: "Cari alat pinjaman...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
