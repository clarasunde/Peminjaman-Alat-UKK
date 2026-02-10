class RiwayatKembali {
  final int id;
  final String tanggalKembali;
  final String status; // Menunggu atau Disetujui
  final List<String> namaAlat;
  final String gambarAlat;

  RiwayatKembali({
    required this.id,
    required this.tanggalKembali,
    required this.status,
    required this.namaAlat,
    required this.gambarAlat,

  });
}
class Alat {
  final String id;
  final String nama;
  final String deskripsi;
  final String gambar;
  final int stok;

  Alat({required this.id, required this.nama, required this.deskripsi, required this.gambar, required this.stok});
}