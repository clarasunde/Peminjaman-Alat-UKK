class RiwayatKembali {
  final int id; // id_pengembalian
  final int idPeminjaman; // Penting untuk relasi
  final String tanggalKembali;
  final String status; // Akan berisi 'selesai' secara otomatis oleh trigger
  final List<String> namaAlat;
  final double denda; // Menambahkan field denda dari ERD

  RiwayatKembali({
    required this.id,
    required this.idPeminjaman,
    required this.tanggalKembali,
    required this.status,
    required this.namaAlat,
    required this.denda,
  });

  factory RiwayatKembali.fromJson(Map<String, dynamic> json) {
    return RiwayatKembali(
      id: json['id_pengembalian'],
      idPeminjaman: json['id_peminjaman'],
      tanggalKembali: json['tanggal_kembali'],
      // Mengambil status dari join tabel peminjaman
      status: json['peminjaman']['status'] ?? 'selesai', 
      denda: (json['total_denda'] ?? 0).toDouble(),
      // Mapping list nama alat dari hasil join detail_peminjaman
      namaAlat: List<String>.from(json['nama_alat_list'] ?? []),
    );
  }
}