class NotifikasiModel {
  final int idNotif;
  final String judul;
  final String pesan;
  final bool isRead;
  final String jenis;

  NotifikasiModel({
    required this.idNotif,
    required this.judul,
    required this.pesan,
    required this.isRead,
    required this.jenis,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotif: json['id_notif'] ?? 0,
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      isRead: json['is_read'] ?? false,
      jenis: json['jenis_notif'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notif': idNotif,
      'judul': judul,
      'pesan': pesan,
      'is_read': isRead,
      'jenis_notif': jenis,
    };
  }
}
