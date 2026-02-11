import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Notifikasi")),

      body: StreamBuilder(
        stream: service.streamNotif(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text("Belum ada notifikasi"));
          }

          return ListView.builder(
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
                    await service.markAsRead(n.idNotif);

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
          );
        },
      ),
    );
  }
}
