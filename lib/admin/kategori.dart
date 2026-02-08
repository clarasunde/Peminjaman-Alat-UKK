import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormKategori extends StatefulWidget {
  final Map<String, dynamic>? kategori;

  const FormKategori({super.key, this.kategori});

  @override
  State<FormKategori> createState() => _FormKategoriState();
}

class _FormKategoriState extends State<FormKategori> {
  final supabase = Supabase.instance.client;
  final _namaController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.kategori != null) {
      _namaController.text = widget.kategori!['nama_kategori'];
    }
  }

  Future<void> _simpan() async {
    if (_namaController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = {"nama_kategori": _namaController.text.trim()};

      if (widget.kategori == null) {
        await supabase.from('kategori').insert(data);
      } else {
        await supabase.from('kategori')
            .update(data)
            .eq('id_kategori', widget.kategori!['id_kategori']);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.kategori != null;

    // Ukuran disesuaikan agar teks "Simpan Perubahan" muat satu baris
    double widthBatal = isEdit ? 133 : 145;
    double widthSimpan = isEdit ? 194 : 145;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Kategori" : "Tambah Kategori", 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4C90),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Input Nama Kategori (343 x 50)
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
            child: SizedBox(
              width: 343,
              height: 50,
              child: TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: "Nama Kategori",
                  labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: "Masukkan nama kategori....",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF1E4C90)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF1E4C90)),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Tombol Aksi di bagian bawah
          Container(
            padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Batal
                SizedBox(
                  width: widthBatal,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9D9D9),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: EdgeInsets.zero, // Menghilangkan padding internal
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      "Batal", 
                      style: TextStyle(fontSize: 18),
                      maxLines: 1, // Memaksa teks satu baris
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Simpan Perubahan / Tambah
                SizedBox(
                  width: widthSimpan,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF112D55),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero, // Menghilangkan padding internal
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      _isLoading ? "..." : (isEdit ? "Simpan Perubahan" : "Tambah"),
                      style: const TextStyle(fontSize: 18),
                      maxLines: 1, // Memaksa teks satu baris
                      softWrap: false, // Mematikan pembungkusan teks
                      overflow: TextOverflow.visible, // Memastikan teks tetap terlihat
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}