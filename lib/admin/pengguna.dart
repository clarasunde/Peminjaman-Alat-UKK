import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormPengguna extends StatefulWidget {
  final Map<String, dynamic>? user;
  const FormPengguna({super.key, this.user});

  @override
  State<FormPengguna> createState() => _FormPenggunaState();
}

class _FormPenggunaState extends State<FormPengguna> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _sandiController = TextEditingController();
  
  String _role = "peminjam"; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _namaController.text = widget.user!['nama'] ?? "";
      _emailController.text = widget.user!['email'] ?? "";
      
      // Mengambil sandi yang tersimpan di kolom 'password' tabel users
      _sandiController.text = widget.user!['password'] ?? "";
      
      String roleFromDb = widget.user!['role']?.toString().toLowerCase() ?? "peminjam";
      if (["admin", "petugas", "peminjam"].contains(roleFromDb)) {
        _role = roleFromDb;
      } else {
        _role = "peminjam";
      }
    }
  }

  Future<void> _saveUser() async {
    // 1. Validasi Nama & Email wajib diisi
    if (_namaController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar("Nama dan Email wajib diisi!");
      return;
    }

    // 2. Validasi Sandi (Wajib diisi jika Tambah Baru)
    if (widget.user == null && _sandiController.text.isEmpty) {
      _showSnackBar("Kata sandi wajib diisi untuk pengguna baru!");
      return;
    }

    // 3. Validasi Minimal 6 Karakter (Jika sandi tidak kosong)
    if (_sandiController.text.isNotEmpty && _sandiController.text.length < 6) {
      _showSnackBar("Sandi minimal harus 6 karakter!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      final dataMap = {
        'nama': _namaController.text,
        'email': _emailController.text.trim(),
        'role': _role,
        'password': _sandiController.text.trim(),
      };

      if (widget.user == null) {
        // --- PROSES TAMBAH USER BARU ---
        final AuthResponse res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _sandiController.text.trim(),
          data: {'nama': _namaController.text, 'role': _role},
        );

        if (res.user != null) {
          await supabase.from('users').insert({
            'id_user': res.user!.id,
            ...dataMap,
          });
        }
      } else {
        // --- PROSES UPDATE DATA USER ---
        await supabase.from('users').update(dataMap).eq('id_user', widget.user!['id_user']);
        
        // Update password di Auth Supabase HANYA jika kotak sandi diisi
        if (_sandiController.text.isNotEmpty) {
          await supabase.auth.updateUser(UserAttributes(
            password: _sandiController.text.trim(),
          ));
        }
      }

      if (mounted) {
        _showSnackBar("Berhasil menyimpan data!");
        Navigator.pop(context);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleError(dynamic e) {
    String msg = e.toString();
    if (msg.contains("over_email_send_rate_limit")) {
      _showSnackBar("Data tersimpan (email konfirmasi tertunda).");
      Navigator.pop(context);
    } else if (msg.contains("already registered")) {
      _showSnackBar("Gagal: Email sudah digunakan!");
    } else {
      _showSnackBar("Error: $msg");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4C90),
        elevation: 0,
        title: Text(widget.user == null ? "Tambah Pengguna" : "Edit Pengguna", 
          style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Informasi Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                
                _buildInputField("Nama Lengkap", _namaController, Icons.person_outline),
                const SizedBox(height: 15),
                
                _buildInputField("Email", _emailController, Icons.email_outlined),
                const SizedBox(height: 15),
                
                _buildInputField("Kata Sandi", _sandiController, Icons.lock_outline, isPassword: true),
                
                // --- KETERANGAN TAMBAHAN DI SINI ---
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("*Minimal 6 karakter", style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      if (widget.user != null)
                        const Text("*Kosongkan jika tidak ingin mengubah kata sandi", 
                          style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: "Pilih Role",
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                    DropdownMenuItem(value: "petugas", child: Text("Petugas")),
                    DropdownMenuItem(value: "peminjam", child: Text("Peminjam")),
                  ],
                  onChanged: (val) => setState(() => _role = val!),
                ),
                
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Color(0xFF1E4C90)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal", style: TextStyle(color: Color(0xFF1E4C90))),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFF1E4C90),
                        ),
                        onPressed: _saveUser,
                        child: Text(widget.user == null ? "Tambah" : "Simpan", 
                          style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}