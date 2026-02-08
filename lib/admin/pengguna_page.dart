import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pengguna.dart'; // FormPengguna

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({super.key});

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  final supabase = Supabase.instance.client;
  String _searchQuery = ""; // State untuk pencarian

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        children: [
          // Header Profil Admin (Sesuai Desain Biru)
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            color: const Color(0xFF1E4C90),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hallo Admin", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("admin@gmail.com", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text("Online", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1E4C90), size: 35),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Row Search & Tombol Tambah
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(4)),
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                          decoration: const InputDecoration(
                            hintText: "Cari pengguna...",
                            hintStyle: TextStyle(fontSize: 12),
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const FormPengguna()));
                        },
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: const Text("Tambah Pengguna", style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A86E8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List Pengguna dengan StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Mengambil stream data asli
              stream: supabase.from('users').stream(primaryKey: ['id_user']).order('nama'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data pengguna"));
                }

                // Logika Filter Pencarian Lokal
                final users = snapshot.data!.where((u) {
                  final nama = u['nama'].toString().toLowerCase();
                  final email = u['email'].toString().toLowerCase();
                  return nama.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // Normalisasi role untuk tampilan (agar huruf depan kapital)
    String roleDisplay = user['role'] != null 
        ? user['role'].toString().substring(0, 1).toUpperCase() + user['role'].toString().substring(1)
        : "Peminjam";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8EFFF),
                  child: Text(
                    user['nama'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF1E4C90), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['nama'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(user['email'] ?? "-", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(roleDisplay, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Online", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                _actionBtn("Edit", Icons.edit, const Color(0xFF1E4C90), const Color(0xFFE8EFFF), () {
                  // Kirim data user ke FormPengguna
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FormPengguna(user: user)));
                }),
                const SizedBox(width: 8),
                _actionBtn("Hapus", Icons.delete, Colors.red, const Color(0xFFFFEAEA), () {
                  _showKonfirmasiHapus(user['id_user'], user['nama']);
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, Color bg, VoidCallback onTap) {
    return InkWell( // Menggunakan InkWell agar ada efek klik
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showKonfirmasiHapus(dynamic id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Hapus Pengguna?", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus $nama? Data akan dihapus permanen.", textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Batal")
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await supabase.from('users').delete().eq('id_user', id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}