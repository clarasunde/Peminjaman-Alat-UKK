import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;

  // Stream untuk mengambil data alat secara real-time
  final Stream<List<Map<String, dynamic>>> _alatStream = 
      Supabase.instance.client.from('alat').stream(primaryKey: ['id_alat']);

  @override
  Widget build(BuildContext context) {
    // Mengambil data user dari provider yang kita buat sebelumnya
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Profil Singkat
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E4C90).withOpacity(0.1),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Halo, ${user?['nama_user'] ?? 'Admin'}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Role: ${user?['role']}", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Daftar Inventaris Alat", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          // List Data Alat dari Tabel 'alat'
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _alatStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final daftarAlat = snapshot.data!;
                return ListView.builder(
                  itemCount: daftarAlat.length,
                  itemBuilder: (context, index) {
                    final alat = daftarAlat[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2, color: Color(0xFF1E4C90)),
                        title: Text(alat['nama_alat'] ?? 'Tanpa Nama'),
                        subtitle: Text("Stok: ${alat['stok']} | Status: ${alat['status']}"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Tambahkan aksi jika item diklik
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E4C90),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // Aksi tambah alat baru
        },
      ),
    );
  }
}