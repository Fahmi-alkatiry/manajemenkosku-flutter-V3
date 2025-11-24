class PropertyModel {
  final int id;
  final String namaProperti;
  final String alamat;
  final String? deskripsi;
  // Update nama field agar lebih jelas
  final int jumlahKamar; 
  final int jumlahTerisi; // Field Baru

  PropertyModel({
    required this.id,
    required this.namaProperti,
    required this.alamat,
    this.deskripsi,
    this.jumlahKamar = 0,
    this.jumlahTerisi = 0,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'],
      namaProperti: json['nama_properti'],
      alamat: json['alamat'],
      deskripsi: json['deskripsi'],
      // Ambil dari key JSON baru yang kita buat di controller tadi
      jumlahKamar: json['total_kamar'] ?? 0, 
      jumlahTerisi: json['kamar_terisi'] ?? 0, 
    );
  }

  // (Optional) toJson tidak terlalu perlu diupdate kecuali kita mau kirim balik model ini
  Map<String, dynamic> toJson() {
    return {
      'nama_properti': namaProperti,
      'alamat': alamat,
      'deskripsi': deskripsi,
    };
  }
}