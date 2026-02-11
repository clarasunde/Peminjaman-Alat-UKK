import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  final supabase = Supabase.instance.client;

  /// 🔥 REALTIME STREAM (otomatis update)
  Stream<List<NotifikasiModel>> streamNotif(String userId) {
    return supabase
        .from('notifikasi')
        .stream(primaryKey: ['id_notif'])
        .eq('id_user', userId)
        .order('created_at', ascending: false)
        .map(
          (data) =>
              data.map((e) => NotifikasiModel.fromJson(e)).toList(),
        );
  }

  /// fetch sekali (optional kalau mau manual refresh)
  Future<List<NotifikasiModel>> getNotif(String userId) async {
    final res = await supabase
        .from('notifikasi')
        .select()
        .eq('id_user', userId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => NotifikasiModel.fromJson(e))
        .toList();
  }

  /// tandai sudah dibaca
  Future<void> markAsRead(int id) async {
    await supabase
        .from('notifikasi')
        .update({'is_read': true})
        .eq('id_notif', id);
  }
}
