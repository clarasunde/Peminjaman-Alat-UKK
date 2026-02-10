import 'package:flutter/material.dart';
import '../models/notifikasi_model.dart';

class DendaDetailPage extends StatelessWidget {
  final NotifikasiModel notif;

  const DendaDetailPage({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengajuan Denda")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(notif.judul,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(notif.pesan),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Bayar"),
            )
          ],
        ),
      ),
    );
  }
}
