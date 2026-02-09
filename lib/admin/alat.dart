import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  XFile? imageFile; 
  String? imageUrl;
  int? selectedKategori;
  
  // Default kondisi untuk alat baru adalah 'tersedia'
  String selectedKondisi = "tersedia"; 

  final picker = ImagePicker();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nama = TextEditingController(text: widget.alat?['nama_alat'] ?? "");
    stok = TextEditingController(text: widget.alat?['stok']?.toString() ?? "");
    spesifikasi = TextEditingController(text: widget.alat?['spesifikasi_alat'] ?? "");

    imageUrl = widget.alat?['gambar_alat'];
    selectedKategori = widget.alat?['id_kategori'];
    
    // Jika sedang edit, ambil kondisi dari database. Jika tambah baru, default 'tersedia'.
    selectedKondisi = widget.alat?['kondisi'] ?? "tersedia";
  }

  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => imageFile = file);
    }
  }

  Future<void> save() async {
    if (nama.text.isEmpty || stok.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Stok wajib diisi!")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      String url = imageUrl ?? "";

      // 1. PROSES UPLOAD KE BUCKET 'alat-images'
      if (imageFile != null) {
        final bytes = await imageFile!.readAsBytes(); 
        final fileExt = imageFile!.path.split('.').last.toLowerCase();
        final actualExt = ['jpg', 'jpeg', 'png'].contains(fileExt) ? fileExt : 'jpg';
        final fileName = "alat_${DateTime.now().millisecondsSinceEpoch}.$actualExt";

        await supabase.storage.from('alat-images').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$actualExt'),
            );
            
        url = supabase.storage.from('alat-images').getPublicUrl(fileName);
      }

      // 2. LOGIKA KETERSEDIAAN BERDASARKAN KONDISI (ENUM)
      // Jika kondisi 'tersedia', ketersediaan = true. Selain itu false.
      bool isAvailable = selectedKondisi == "tersedia";

      final data = {
        "nama_alat": nama.text,
        "stok": int.tryParse(stok.text) ?? 0,
        "spesifikasi_alat": spesifikasi.text,
        "id_kategori": selectedKategori,
        "gambar_alat": url,
        "kondisi": selectedKondisi, // Menggunakan Enum: tersedia, dipinjam, diperbaiki
        "ketersediaan": isAvailable, // Otomatis True jika tersedia
      };

      // 3. OPERASI DATABASE
      if (widget.alat == null) {
        await supabase.from('alat').insert(data);
      } else {
        await supabase
            .from('alat')
            .update(data)
            .eq('id_alat', widget.alat!['id_alat']);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan data: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header Biru
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
          
          // Header Putih
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.alat == null ? "Tambah Alat" : "Edit Alat",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 22),
                )
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // AREA FOTO
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: 189, height: 188,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: blue, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildImageWidget(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  _input("Nama", nama),
                  _input("Stok", stok, number: true),
                  _input("Spesifikasi", spesifikasi, lines: 3),

                  const SizedBox(height: 18),
                  
                  // DROPDOWN KATEGORI
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

                  const SizedBox(height: 18),

                  // DROPDOWN KONDISI (ENUM)
                  DropdownButtonFormField<String>(
                    value: selectedKondisi,
                    decoration: _decoration("Kondisi Alat"),
                    items: const [
                      DropdownMenuItem(value: "tersedia", child: Text("Tersedia")),
                      DropdownMenuItem(value: "dipinjam", child: Text("Dipinjam")),
                      DropdownMenuItem(value: "diperbaiki", child: Text("Sedang Diperbaiki")),
                    ],
                    onChanged: (v) => setState(() => selectedKondisi = v!),
                  ),

                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btnBatal(),
                      const SizedBox(width: 14),
                      _btnSimpan(),
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

  // --- UI HELPERS ---

  Widget _buildImageWidget() {
    if (imageFile != null) {
      return kIsWeb 
        ? Image.network(imageFile!.path, fit: BoxFit.cover) 
        : Image.file(File(imageFile!.path), fit: BoxFit.cover);
    }
    if (imageUrl != null && imageUrl != "") {
      return Image.network(imageUrl!, fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, color: blue, size: 40),
        const SizedBox(height: 6),
        Text("Upload Gambar", style: TextStyle(color: blue, fontSize: 12)),
      ],
    );
  }

  Widget _btnBatal() {
    return SizedBox(
      width: 113, height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text("Batal"),
      ),
    );
  }

  Widget _btnSimpan() {
    return SizedBox(
      width: 199, height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: loading ? null : save,
        child: loading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text("Simpan Perubahan"),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {bool number = false, int lines = 1}) {
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
      labelText: label, filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}