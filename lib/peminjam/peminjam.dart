import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';
import '../auth/logout.dart';
import 'peminjam_alat.dart';
import 'pinjam.dart';
import 'kembali_page.dart';
import 'notifikasi.dart';

class PeminjamPage extends StatefulWidget {
  const PeminjamPage({super.key});

  @override
  State<PeminjamPage> createState() => _PeminjamPageState();
}

class _PeminjamPageState extends State<PeminjamPage> {
  int _selectedIndex = 0;

  final supabase = Supabase.instance.client;

  int jumlahNotif = 0;

  RealtimeChannel? channel;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    getNotifCount();
    realtimeNotif();
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  // ================= NOTIF COUNT =================
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

  void realtimeNotif() {
    channel = supabase
        .channel('notif-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          callback: (_) => getNotifCount(),
        )
        .subscribe();
  }

  // ================= TAB =================
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Stream<List<Map<String, dynamic>>> _getPeminjamanStream(String userId) {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('id_user', userId)
        .order('created_at', ascending: false);
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userData;
    final String userId = user?['id'] ?? '';

    final pages = [
      _buildBerandaPeminjam(user, userId),
      AlatPeminjamPage(userData: user),
      PinjamPage(userData: user),
      KembaliPage(userData: user),
      const LogoutScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1E4C90),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.computer), label: 'Alat'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Pinjam'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_return), label: 'Kembali'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
      decoration: const BoxDecoration(
        color: Color(0xFF1E4C90),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Hallo Peminjam",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(user?['email'] ?? '',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),

          Row(
            children: [
              // 🔔 NOTIF
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotifikasiPage(),
                        ),
                      );
                      getNotifCount();
                    },
                  ),
                  if (jumlahNotif > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$jumlahNotif',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    )
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E4C90)),
              )
            ],
          )
        ],
      ),
    );
  }

  // ================= BERANDA =================
  Widget _buildBerandaPeminjam(Map<String, dynamic>? user, String userId) {
    return Column(
      children: [
        _buildHeader(user),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        "Pinjam Alat",
                        Icons.add_circle,
                        Colors.green,
                        () => _onItemTapped(1),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildQuickAction(
                        "Kembalikan",
                        Icons.assignment_return,
                        Colors.orange,
                        () => _onItemTapped(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= QUICK ACTION (INI YG TADI HILANG) =================
  Widget _buildQuickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
