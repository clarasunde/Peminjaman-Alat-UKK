import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p; // Tambahkan path: ^1.9.0 di pubspec.yaml jika ingin ambil ekstensi file dengan mudah

class FormAlatPage extends StatefulWidget {
  final Map<String, dynamic>? alat;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? currentCategory;

  const FormAlatPage({
    super.key,
    this.alat,
    this.categories = const [],
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

  Map<String, dynamic>? selectedKat;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data jika dalam mode edit
    namaController = TextEditingController(text: widget.alat?['nama_alat'] ?? '');
    stokController = TextEditingController(text: widget.alat?['stok']?.toString() ?? '0');
    spesifikasiController = TextEditingController(text: widget.alat?['spesifikasi_alat'] ?? '');
    _initCategory();
  }

  void _initCategory() {
    if (widget.alat != null && widget.categories.isNotEmpty) {
      try {
        setState(() {
          selectedKat = widget.categories.firstWhere(
            (c) => c['id_kategori'].toString() == widget.alat!['id_kategori'].toString(),
          );
        });
      } catch (e) {
        selectedKat = widget.categories.isNotEmpty ? widget.categories.first : null;
      }
    } else if (widget.currentCategory != null) {
      selectedKat = widget.currentCategory;
    } else if (widget.categories.isNotEmpty) {
      selectedKat = widget.categories.first;
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
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70 // Kualitas 70% agar file tidak terlalu berat di storage
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  /// FUNGSI UTAMA: MENYAMBUNGKAN KE SUPABASE (DATABASE & STORAGE)
  Future<void> _saveData() async {
    final String namaAlat = namaController.text.trim();
    
    // 1. Validasi Input
    if (namaAlat.isEmpty) {
      _showSnackBar("Nama alat harus diisi", Colors.orange);
      return;
    }
    if (selectedKat == null) {
      _showSnackBar("Silakan pilih kategori", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 2. Logika Penanganan Gambar
      String? imageUrl = widget.alat?['gambar_alat'];

      if (_imageFile != null) {
        // Ambil ekstensi asli (jpg/png) agar file tidak rusak
        final String fileExt = p.extension(_imageFile!.path).isEmpty 
            ? '.png' 
            : p.extension(_imageFile!.path);
            
        // Buat nama file: nama_alat_timestamp.png
        final String fileName = '${namaAlat.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$fileExt';

        // Upload ke bucket 'alat-images' sesuai screenshot Storage Anda
        await supabase.storage.from('alat-images').upload(
          fileName,
          _imageFile!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        // Ambil Public URL karena bucket Anda berstatus PUBLIC
        imageUrl = supabase.storage.from('alat-images').getPublicUrl(fileName);
      }

      // 3. Persiapan Data (Menyesuaikan kolom int4 dan bool di screenshot Table Editor)
      final int stokValue = int.tryParse(stokController.text) ?? 0;
      final Map<String, dynamic> data = {
        'nama_alat': namaAlat,
        'stok': stokValue,
        'spesifikasi_alat': spesifikasiController.text.trim(),
        'id_kategori': selectedKat!['id_kategori'],
        'gambar_alat': imageUrl, 
        'kondisi': widget.alat?['kondisi'] ?? 'tersedia', // Sesuaikan nama kolom di DB Anda
        'ketersediaan': stokValue > 0, // Mengisi kolom bool secara otomatis
      };

      // 4. Operasi Database
      if (widget.alat == null) {
        await supabase.from('alat').insert(data);
        if (mounted) _showSnackBar("Alat berhasil ditambahkan!", Colors.green);
      } else {
        await supabase
            .from('alat')
            .update(data)
            .eq('id_alat', widget.alat!['id_alat']);
        if (mounted) _showSnackBar("Perubahan berhasil disimpan!", Colors.blue);
      }

      if (mounted) Navigator.pop(context, true);

    } on PostgrestException catch (error) {
      _showSnackBar("Database Error: ${error.message}", Colors.red);
    } on StorageException catch (error) {
      _showSnackBar("Storage Error: ${error.message}", Colors.red);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan sistem: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                children: [
                  _buildImagePickerBox(),
                  const SizedBox(height: 10),
                  const Text("Foto Alat", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 30),
                  _buildInputRow("Nama Alat", namaController, "Masukkan nama alat"),
                  _buildInputRow("Stok", stokController, "0", isNumber: true),
                  _buildInputRow("Spesifikasi", spesifikasiController, "Detail spesifikasi...", maxLines: 3),
                  _buildCategorySelector(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 10),
      decoration: const BoxDecoration(
          color: Color(0xFF1E4C90),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(
            widget.alat == null ? "Tambah Alat Baru" : "Edit Data Alat",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.file(_imageFile!, fit: BoxFit.cover))
            : (widget.alat?['gambar_alat'] != null 
                ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.network(widget.alat!['gambar_alat'], fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text("Pilih Gambar", style: TextStyle(color: Colors.grey[600])),
                    ],
                  )),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kategori Alat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategorySelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedKat?['nama_kategori'] ?? 'Pilih Kategori', style: const TextStyle(fontSize: 16)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1E4C90)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: Color(0xFF1E4C90)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Color(0xFF1E4C90), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4C90),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _isUploading ? null : _saveData,
            child: _isUploading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.alat == null ? "Tambah Alat" : "Simpan Perubahan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showCategorySelector() {
    if (widget.categories.isEmpty) {
      _showSnackBar("Data kategori kosong!", Colors.red);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Kategori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: widget.categories.map((cat) => ListTile(
                  leading: const Icon(Icons.category_outlined, color: Color(0xFF1E4C90)),
                  title: Text(cat['nama_kategori']),
                  onTap: () {
                    setState(() => selectedKat = cat);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}