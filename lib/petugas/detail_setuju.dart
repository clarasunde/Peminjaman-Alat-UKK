import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DetailSetujuPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailSetujuPage({super.key, required this.item});

  @override
  State<DetailSetujuPage> createState() => _DetailSetujuPageState();
}

class _DetailSetujuPageState extends State<DetailSetujuPage> {
  final supabase = Supabase.instance.client;

  DateTime tanggalAmbil = DateTime.now();
  DateTime tanggalKembali = DateTime.now().add(const Duration(days: 3));

  // =====================================================
  // UPDATE STATUS
  // =====================================================
  Future<void> updateStatus(String status) async {
    await supabase
        .from('peminjaman')
        .update({
          'status': status,
          'tanggal_pinjam': tanggalAmbil.toIso8601String(),
          'tanggal_kembali': tanggalKembali.toIso8601String(),
        })
        .eq('id_peminjaman', widget.item['id_peminjaman']);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status $status berhasil")),
      );
    }
  }

  // =====================================================
  @override
  Widget build(BuildContext context) {
    final user = widget.item['users'];
    final detailList = widget.item['detail_peminjaman'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Persetujuan",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E4C90),
      ),
      backgroundColor: Colors.grey[100],

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // =================================================
            // USER CARD
            // =================================================
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1E4C90),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user['nama']),
                subtitle: Text(user['email']),
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // LIST ALAT
            // =================================================
            ...detailList.map<Widget>((d) {
              final alat = d['alat'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          alat['gambar_alat'] ?? '',
                          width: 70,
                          height: 70,
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
                            Text(alat['nama_alat'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text("Jumlah: ${d['jumlah']}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 25),

            // =================================================
            // TANGGAL
            // =================================================
            _dateTile(
              "Tanggal Ambil",
              tanggalAmbil,
              (picked) => setState(() => tanggalAmbil = picked),
            ),

            const SizedBox(height: 14),

            _dateTile(
              "Tanggal Kembali",
              tanggalKembali,
              (picked) => setState(() => tanggalKembali = picked),
            ),

            const SizedBox(height: 30),

            // =================================================
            // BUTTON
            // =================================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => updateStatus('ditolak'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    child: const Text("Tolak"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => updateStatus('disetujui'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4C90)),
                    child: const Text("Setujui",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  Widget _dateTile(
      String title, DateTime value, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yyyy').format(value)),
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        )
      ],
    );
  }
}
