class Alat {
  final int idAlat; // Sesuaikan dengan int4 di database
  final int idKategori;
  final String namaAlat;
  final int stok;
  final String gambarAlat;
  final String spesifikasiAlat; // Sesuai kolom spesifikasi_alat
  final String kondisi; // Untuk menampung enum kondisi_alat

  Alat({
    required this.idAlat,
    required this.idKategori,
    required this.namaAlat,
    required this.stok,
    required this.gambarAlat,
    required this.spesifikasiAlat,
    required this.kondisi,
  });

  // Fungsi untuk mengubah data dari Database (Map) ke Object Flutter
  factory Alat.fromJson(Map<String, dynamic> json) {
    return Alat(
      idAlat: json['id_alat'],
      idKategori: json['id_kategori'],
      namaAlat: json['nama_alat'],
      stok: json['stok'],
      gambarAlat: json['gambar_alat'] ?? '',
      spesifikasiAlat: json['spesifikasi_alat'] ?? '',
      kondisi: json['kondisi'],
    );
  }
}