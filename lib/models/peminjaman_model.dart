class PeminjamanModel {
  final int idPeminjaman; // int4 di database
  final String idUser;    // uuid di database
  final DateTime tanggalPinjam;
  final DateTime? tanggalKembali; // Bisa null jika belum kembali
  final String status;    // enum: menunggu, disetujui, ditolak, selesai

  PeminjamanModel({
    required this.idPeminjaman,
    required this.idUser,
    required this.tanggalPinjam,
    this.tanggalKembali,
    required this.status,
  });

  // Mapping dari Database ke Object
  factory PeminjamanModel.fromJson(Map<String, dynamic> json) {
    return PeminjamanModel(
      idPeminjaman: json['id_peminjaman'],
      idUser: json['id_user'],
      tanggalPinjam: DateTime.parse(json['tanggal_pinjam']),
      tanggalKembali: json['tanggal_kembali'] != null 
          ? DateTime.parse(json['tanggal_kembali']) 
          : null,
      status: json['status'], // Pastikan value-nya sesuai enum
    );
  }

  // Mapping dari Object ke Database (untuk Update Status)
  Map<String, dynamic> toJson() {
    return {
      'status': status, // Ini yang akan memicu trigger di database
    };
  }
}