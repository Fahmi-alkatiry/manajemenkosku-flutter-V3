class RoomModel {
  final int id;
  final String nomorKamar;
  final String tipe;
  final double harga;
  final String status; // 'Tersedia', 'Ditempati', 'Diperbaiki'
  final String? deskripsi;
  final int propertiId;

  RoomModel({
    required this.id,
    required this.nomorKamar,
    required this.tipe,
    required this.harga,
    required this.status,
    this.deskripsi,
    required this.propertiId,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'],
      nomorKamar: json['nomor_kamar'],
      tipe: json['tipe'],
      harga: (json['harga'] ?? 0).toDouble(),
      status: json['status'],
      deskripsi: json['deskripsi'],
      propertiId: json['propertiId'],
    );
  }
}