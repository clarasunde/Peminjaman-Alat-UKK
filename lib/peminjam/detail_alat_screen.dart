import 'package:flutter/material.dart';
import 'keranjang_screen.dart';

// 🔥 SATU GLOBAL LIST (HANYA DI FILE INI SAJA)
List<Map<String, dynamic>> keranjangGlobal = [];

class DetailAlatScreen extends StatefulWidget {
  final Map<String, dynamic> alat;

  const DetailAlatScreen({super.key, required this.alat});

  @override
  State<DetailAlatScreen> createState() => _DetailAlatScreenState();
}

class _DetailAlatScreenState extends State<DetailAlatScreen> {
  int jumlah = 1;

  // ===============================
  // TAMBAH KE KERANJANG (ANTI DUPLIKAT)
  // ===============================
  void tambahKeranjang() {
    final index = keranjangGlobal.indexWhere(
      (e) => e['id_alat'] == widget.alat['id_alat'],
    );

    if (index != -1) {
      keranjangGlobal[index]['jumlah_pinjam'] += jumlah;
    } else {
      keranjangGlobal.add({
        ...widget.alat,
        'jumlah_pinjam': jumlah,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final namaAlat = widget.alat['nama_alat'] ?? '-';
    final gambarUrl = widget.alat['gambar_alat'] ?? '';
    final stok = widget.alat['stok'] ?? 0;
    final spesifikasi =
        widget.alat['spesifikasi_alat'] ?? 'Belum ada spesifikasi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Alat",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================= FOTO =================
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[100],
              child: gambarUrl.isNotEmpty
                  ? Image.network(
                      gambarUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported, size: 80),
                    )
                  : const Icon(Icons.image_not_supported, size: 80),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(namaAlat,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Text(spesifikasi),

                  const SizedBox(height: 10),

                  Text("Stok: $stok"),

                  const Divider(height: 40),

                  // ================= JUMLAH =================
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah Pinjam"),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (jumlah > 1) {
                                setState(() => jumlah--);
                              }
                            },
                          ),
                          Text("$jumlah",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (jumlah < stok) {
                                setState(() => jumlah++);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ================= BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart,
                          color: Colors.white),
                      label: const Text("MASUKKAN KERANJANG",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4C90),
                      ),

                      // 🔥 FIX DI SINI
                      onPressed: stok > 0
                          ? () {
                              tambahKeranjang();

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "$namaAlat masuk keranjang"),
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const KeranjangScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
