import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  final supabase = Supabase.instance.client;

  Future<List<NotifikasiModel>> getNotif(String userId) async {
    final res = await supabase
        .from('notifikasi')
        .select()
        .eq('id_user', userId); // ❌ hapus order created_at

    return (res as List)
        .map((e) => NotifikasiModel.fromJson(e))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    await supabase
        .from('notifikasi')
        .update({'is_read': true})
        .eq('id_notif', id);
  }
}
