import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormAlatPage extends StatefulWidget {
  final Map<String, dynamic>? alat;
  // Menambahkan default value agar tidak error saat dipanggil tanpa data
  final List<Map<String, dynamic>> categories; 
  final Map<String, dynamic>? currentCategory;

  const FormAlatPage({
    super.key, 
    this.alat, 
    this.categories = const [], // Default list kosong
    this.currentCategory,
  });

  @override
  State<FormAlatPage> createState() => _FormAlatPageState();
}

class _FormAlatPageState extends State<FormAlatPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  
  late TextEditingController namaController;
  late TextEditingController stokController;
  late TextEditingController spesifikasiController;
  late Map<String, dynamic> selectedKat; 
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.alat?['nama_alat'] ?? '');
    stokController = TextEditingController(text: widget.alat?['stok']?.toString() ?? '');
    spesifikasiController = TextEditingController(text: widget.alat?['spesifikasi_alat'] ?? '');
    
    // Logika pengaman agar tidak error jika categories kosong
    if (widget.alat != null && widget.categories.isNotEmpty) {
      selectedKat = widget.categories.firstWhere(
        (c) => c['id_kategori'] == widget.alat!['id_kategori'],
        orElse: () => widget.categories[0],
      );
    } else if (widget.currentCategory != null) {
      selectedKat = widget.currentCategory!;
    } else if (widget.categories.isNotEmpty) {
      selectedKat = widget.categories[0];
    } else {
      // Fallback jika benar-benar kosong
      selectedKat = {'id_kategori': 0, 'nama_kategori': 'Pilih Kategori'};
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    stokController.dispose();
    spesifikasiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveData() async {
    if (namaController.text.trim().isEmpty) {
      _showSnackBar("Nama alat harus diisi", Colors.orange);
      return;
    }
    if (selectedKat['id_kategori'] == 0) {
      _showSnackBar("Silakan pilih kategori", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = widget.alat?['gambar_alat'];

      if (_imageFile != null) {
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = 'alat/$fileName';
        await supabase.storage.from('inventaris').upload(path, _imageFile!);
        imageUrl = supabase.storage.from('inventaris').getPublicUrl(path);
      }

      final data = {
        'nama_alat': namaController.text.trim(),
        'stok': int.tryParse(stokController.text) ?? 0,
        'spesifikasi_alat': spesifikasiController.text.trim(),
        'id_kategori': selectedKat['id_kategori'],
        'gambar_alat': imageUrl,
        'kondisi': widget.alat?['kondisi'] ?? 'Baik',
        'ketersediaan': widget.alat?['ketersediaan'] ?? true,
      };

      if (widget.alat == null) {
        await supabase.from('alat').insert(data);
        _showSnackBar("Data berhasil ditambah!", Colors.green);
      } else {
        await supabase.from('alat').update(data).match({'id_alat': widget.alat!['id_alat']});
        _showSnackBar("Data berhasil diperbarui!", Colors.blue);
      }

      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      _showSnackBar("Gagal menyimpan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header biru sesuai mockup
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 10),
            color: const Color(0xFF1E4C90),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.alat == null ? "Tambah Alat Baru" : "Edit Alat",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                children: [
                  // Box Upload Gambar (Mockup style)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160, width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.file(_imageFile!, fit: BoxFit.cover))
                          : (widget.alat?['gambar_alat'] != null 
                              ? ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(widget.alat!['gambar_alat'], fit: BoxFit.cover))
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                                    SizedBox(height: 5),
                                    Icon(Icons.upload, size: 20, color: Colors.grey),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Upload Gambar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 30),

                  // Input Fields
                  _buildInputRow("Nama  :", namaController, ""),
                  _buildInputRow("Stok  :", stokController, "", isNumber: true),
                  _buildInputRow("Spesifikasi :", spesifikasiController, "", maxLines: 3),
                  
                  // Selector Kategori
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        const SizedBox(width: 90, child: Text("Kategori :", style: TextStyle(fontWeight: FontWeight.w500))),
                        Expanded(
                          child: InkWell(
                            onTap: _showCategorySelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedKat['nama_kategori'] ?? 'Pilih Kategori'),
                                  const Icon(Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("Batal", Colors.grey.shade300, Colors.black, () => Navigator.pop(context)),
                      _buildActionButton(
                        _isUploading ? "..." : (widget.alat == null ? "Tambah" : "Simpan"), 
                        const Color(0xFF1E4C90), 
                        Colors.white, 
                        _isUploading ? () {} : _saveData
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

  Widget _buildInputRow(String label, TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bg, Color txt, VoidCallback onPressed) {
    return SizedBox(
      width: 140,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showCategorySelector() {
    if (widget.categories.isEmpty) {
      _showSnackBar("Data kategori tidak tersedia", Colors.red);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: widget.categories.map((cat) => ListTile(
          title: Text(cat['nama_kategori']),
          onTap: () {
            setState(() => selectedKat = cat);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }
}