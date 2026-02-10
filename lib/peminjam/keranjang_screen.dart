import 'package:flutter/material.dart';
import 'detail_alat_screen.dart'; // 🔥 pakai keranjangGlobal
import 'pengajuan_alat_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {

  // ================= REMOVE ITEM =================
  void _removeItem(int index) {
    setState(() {
      keranjangGlobal.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Keranjang Pinjaman",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E4C90),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: keranjangGlobal.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // ================= LIST =================
                Expanded(
                  child: ListView.builder(
                    itemCount: keranjangGlobal.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (_, index) {
                      final item = keranjangGlobal[index];
                      return _buildCartItem(item, index);
                    },
                  ),
                ),

                // ================= BOTTOM =================
                _buildBottomAction(),
              ],
            ),
    );
  }

  // ================= EMPTY =================
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text(
            "Keranjang masih kosong",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= ITEM CARD =================
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['gambar_alat'] ?? '',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_alat'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  "Jumlah: ${item['jumlah_pinjam']} Unit",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete, color: Colors.red),
          )
        ],
      ),
    );
  }

  // ================= BOTTOM ACTION =================
  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Barang:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${keranjangGlobal.length} Alat",
                style: const TextStyle(
                  color: Color(0xFF1E4C90),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4C90),
              ),
              onPressed: () {
                if (keranjangGlobal.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PengajuanAlatScreen(items: keranjangGlobal),
                    ),
                  );
                }
              },
              child: const Text(
                "AJUKAN PEMINJAMAN",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
