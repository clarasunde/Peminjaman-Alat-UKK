import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? userData;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => _supabase.auth.currentSession != null;

  // =========================
  // LOGIN
  // =========================
  Future<String?> login(String email, String password) async {
    _setLoading(true);

    try {
      /// 1️⃣ Login Auth
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        _setLoading(false);
        return "Login gagal";
      }

      /// 2️⃣ Ambil data users table (FIX KOLOM DI SINI)
      final data = await _supabase
          .from('users')
          .select()
          .eq('id_user', res.user!.id) // ✅ PERBAIKAN PENTING
          .single();

      if (data == null) {
        _setLoading(false);
        return "Profil tidak ditemukan. Trigger belum jalan.";
      }

      if (data['role'] == null) {
        _setLoading(false);
        return "Role belum diatur.";
      }

      userData = data;

      _setLoading(false);

      /// return role supaya login page yang redirect
      return data['role'];

    } on AuthException catch (e) {
      _setLoading(false);
      return e.message;

    } catch (e) {
      _setLoading(false);
      return "Error sistem: $e";
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _supabase.auth.signOut();
    userData = null;
    notifyListeners();
  }


  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> signOut() async {}
}
