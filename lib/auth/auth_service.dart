import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? userData;

  User? get currentUser => _supabase.auth.currentUser;

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Sign in ke Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // 2. Mengambil profil dari tabel public.users
        // PERBAIKAN: Menggunakan 'id' sesuai kolom di database
        final data = await _supabase
            .from('users')
            .select()
            .eq('id', res.user!.id) 
            .maybeSingle(); 

        // 3. Validasi keberadaan data profil
        if (data == null) {
          _isLoading = false;
          notifyListeners();
          return "Profil tidak ditemukan di tabel users. Pastikan Trigger SQL berjalan.";
        }

        // 4. Cek Role (admin, petugas, atau peminjam)
        if (data['role'] == null || data['role'].toString().isEmpty) {
          _isLoading = false;
          notifyListeners();
          return "Role akun Anda belum diatur. Silakan hubungi Admin.";
        }

        userData = data;
        print("Login Berhasil! Role: ${userData!['role']}");
      }
      
      _isLoading = false;
      notifyListeners();
      return null; 
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message; 
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Terjadi kesalahan sistem: $e";
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    userData = null;
    notifyListeners();
  }

  bool get isLoggedIn => _supabase.auth.currentSession != null;
}