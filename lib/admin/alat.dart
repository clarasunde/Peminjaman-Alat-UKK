import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class FormAlatPage extends StatefulWidget {
  final Map<String, dynamic>? alat;

  const FormAlatPage({super.key, this.alat});

  @override
  State<FormAlatPage> createState() => _FormAlatPageState();
}

class _FormAlatPageState extends State<FormAlatPage> {
  SupabaseClient get supabase => Supabase.instance.client;

  final blue = const Color(0xFF1E4C90);

  late TextEditingController nama;
  late TextEditingController stok;
  late TextEditingController spesifikasi;

  File? imageFile;
  String? imageUrl;
  int? selectedKategori;

  final picker = ImagePicker();
  bool loading = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    nama = TextEditingController(text: widget.alat?['nama_alat'] ?? "");
    stok = TextEditingController(text: widget.alat?['stok']?.toString() ?? "");
    spesifikasi =
        TextEditingController(text: widget.alat?['spesifikasi_alat'] ?? "");

    imageUrl = widget.alat?['gambar_alat'];
    selectedKategori = widget.alat?['id_kategori'];
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => imageFile = File(file.path));
  }

  // ================= SAVE =================
  Future<void> save() async {
    setState(() => loading = true);

    try {
      String url = imageUrl ?? "";

      if (imageFile != null) {
        final ext = p.extension(imageFile!.path);
        final name = "alat_${DateTime.now().millisecondsSinceEpoch}$ext";

        await supabase.storage.from('alat-images').upload(name, imageFile!);
        url = supabase.storage.from('alat-images').getPublicUrl(name);
      }

      final data = {
        "nama_alat": nama.text,
        "stok": int.tryParse(stok.text) ?? 0,
        "spesifikasi_alat": spesifikasi.text,
        "id_kategori": selectedKategori,
        "gambar_alat": url,
      };

      if (widget.alat == null) {
        await supabase.from('alat').insert(data);
      } else {
        await supabase
            .from('alat')
            .update(data)
            .eq('id_alat', widget.alat!['id_alat']);
      }

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => loading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [

          // =================================================
          // 🔵 HEADER BIRU
          // =================================================
          Container(
            height: 95,
            padding: const EdgeInsets.only(top: 50),
            width: double.infinity,
            color: blue,
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // =================================================
          // ⚪ HEADER PUTIH (TITLE)
          // =================================================
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Edit Alat",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22),
                )
              ],
            ),
          ),

          // =================================================
          // 🔥 FORM AREA
          // =================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // =================================================
                  // 🔥 FOTO 189x188 + SHADOW
                  // =================================================
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 189,
                      height: 188,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: imageFile != null
                          ? Image.file(imageFile!, fit: BoxFit.contain)
                          : (imageUrl != null && imageUrl != "")
                              ? Image.network(imageUrl!, fit: BoxFit.contain)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        color: blue, size: 40),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Upload Gambar",
                                      style: TextStyle(
                                        color: blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  _input("Nama", nama),
                  _input("Stok", stok, number: true),
                  _input("Spesifikasi", spesifikasi, lines: 3),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<int>(
                    value: selectedKategori,
                    decoration: _decoration("Kategori"),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Laptop")),
                      DropdownMenuItem(value: 2, child: Text("Proyektor")),
                      DropdownMenuItem(value: 3, child: Text("Kamera")),
                    ],
                    onChanged: (v) => setState(() => selectedKategori = v),
                  ),

                  const SizedBox(height: 40),

                  // =================================================
                  // 🔥 BUTTON FIX SIZE (PERSIS MOCKUP)
                  // =================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // BATAL
                      SizedBox(
                        width: 113,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // SIMPAN
                      SizedBox(
                        width: 199,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: loading ? null : save,
                          child: const Text("Simpan Perubahan"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= INPUT =================
  Widget _input(String label, TextEditingController c,
      {bool number = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: _decoration(label),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
