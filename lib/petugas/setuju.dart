import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class PersetujuanPage extends StatefulWidget {
  const PersetujuanPage({super.key});

  @override
  State<PersetujuanPage> createState() => _PersetujuanPageState();
}

class _PersetujuanPageState extends State<PersetujuanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Diubah menjadi 4 jika mengikuti enum awalmu (menunggu, disetujui, ditolak, selesai)
    // Di sini kita gunakan 3 tab sesuai UI kamu
    _tabController = TabController(length: 3, vsync: this);
  }

  Stream<List<Map<String, dynamic>>> _getPeminjamanStream(String status) {
    return supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .eq('status', status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Persetujuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Perlu Disetujui"),
            Tab(text: "Disetujui"),
            Tab(text: "Ditolak"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab('menunggu'), // Gunakan huruf kecil sesuai Enum Supabase
          _buildListTab('disetujui'),
          _buildListTab('ditolak'),
        ],
      ),
    );
  }

  Widget _buildListTab(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getPeminjamanStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada permintaan"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            return _buildRequestCard(item);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF1E4C90),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nama Peminjam", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(item['status'] ?? 'menunggu', 
                        style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.laptop, size: 30, color: Color(0xFF1E4C90)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID Alat: ${item['id_alat']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("Tgl Ajukan: ${item['tanggal_pinjam'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (item['status'] == 'menunggu')
                  ElevatedButton(
                    onPressed: () => _openDetailDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4C90),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Detail", style: TextStyle(color: Colors.white)),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openDetailDialog(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailBottomSheet(item: item, supabase: supabase),
    );
  }
}

class _DetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final SupabaseClient supabase;
  const _DetailBottomSheet({required this.item, required this.supabase});

  @override
  State<_DetailBottomSheet> createState() => _DetailBottomSheetState();
}

class _DetailBottomSheetState extends State<_DetailBottomSheet> {
  DateTime selectedDateAmbil = DateTime.now();
  DateTime selectedDateKembali = DateTime.now().add(const Duration(days: 3));

  // Fungsi Approve yang kamu minta sudah dimasukkan ke sini
  Future<void> _processStatus(String newStatus) async {
    try {
      if (newStatus == 'disetujui') {
        await widget.supabase.from('peminjaman').update({
          'status': 'disetujui',
          'tanggal_pinjam': selectedDateAmbil.toIso8601String(),
          'tanggal_kembali': selectedDateKembali.toIso8601String(),
        }).eq('id_peminjaman', widget.item['id_peminjaman']);
      } else {
        await widget.supabase.from('peminjaman').update({
          'status': 'ditolak',
        }).eq('id_peminjaman', widget.item['id_peminjaman']);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil update status menjadi $newStatus")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("Detail Persetujuan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          
          const Text("Tanggal Ambil", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _dateTile(DateFormat('dd/MM/yyyy').format(selectedDateAmbil), Icons.calendar_month, () async {
            final picked = await showDatePicker(context: context, initialDate: selectedDateAmbil, firstDate: DateTime.now(), lastDate: DateTime(2030));
            if (picked != null) setState(() => selectedDateAmbil = picked);
          }),

          const SizedBox(height: 15),
          const Text("Tanggal Harus Kembali", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _dateTile(DateFormat('dd/MM/yyyy').format(selectedDateKembali), Icons.event_available, () async {
            final picked = await showDatePicker(context: context, initialDate: selectedDateKembali, firstDate: selectedDateAmbil, lastDate: DateTime(2030));
            if (picked != null) setState(() => selectedDateKembali = picked);
          }),

          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _processStatus('ditolak'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Tolak"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _processStatus('disetujui'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E4C90)),
                  child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _dateTile(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Icon(icon, size: 18, color: Colors.grey)],
        ),
      ),
    );
  }
}