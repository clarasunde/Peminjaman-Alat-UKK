class NotifikasiModel {
  final int id;
  final String judul;
  final String pesan;
  final bool isRead;
  final String jenis;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.isRead,
    required this.jenis,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id_notif'],
      judul: json['judul'],
      pesan: json['pesan'],
      isRead: json['is_read'],
      jenis: json['jenis_notif'],
    );
  }
}
