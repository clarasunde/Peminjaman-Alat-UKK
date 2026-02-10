import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi_model.dart';
import '../peminjam/notifikasi_service.dart';
import 'denda_detail_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final service = NotifikasiService();
  final supabase = Supabase.instance.client;

  List<NotifikasiModel> data = [];

  @override
  void initState() {
    super.initState();
    fetch();
    realtime();
  }

  // ambil data notif
  Future<void> fetch() async {
    final userId = supabase.auth.currentUser!.id;
    final res = await service.getNotif(userId);

    setState(() => data = res);
  }

  // realtime listen
  void realtime() {
    supabase
        .channel('notif-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifikasi',
          callback: (_) => fetch(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Notifikasi")),

      body: data.isEmpty
          ? const Center(child: Text("Belum ada notifikasi"))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (c, i) {
                final n = data[i];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(n.judul),
                    subtitle: Text(n.pesan),
                    trailing: !n.isRead
                        ? const Icon(Icons.circle, color: Colors.red, size: 10)
                        : null,
                    onTap: () async {
                      await service.markAsRead(n.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DendaDetailPage(notif: n),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
