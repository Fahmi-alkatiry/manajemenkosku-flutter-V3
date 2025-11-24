import '../../../../core/constants/api_constants.dart';

class TenantCrudModel {
  final int id;
  final String nama;
  final String email;
  final String noHp;
  final String? alamat;
  final String? fotoKtp;
  final bool isActive;
  // --- FIELD BARU ---
  final String? propertyName;
  final String? roomNumber;

  TenantCrudModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    this.alamat,
    this.fotoKtp,
    required this.isActive,
    this.propertyName,
    this.roomNumber,
  });

  factory TenantCrudModel.fromJson(Map<String, dynamic> json) {
    // Parsing data kontrak nested
    String? propName;
    String? roomNo;
    bool active = false;

    if (json['kontrak'] != null && (json['kontrak'] as List).isNotEmpty) {
      final contract = json['kontrak'][0]; // Ambil kontrak pertama
      active = true;
      if (contract['kamar'] != null) {
        roomNo = contract['kamar']['nomor_kamar'];
        if (contract['kamar']['properti'] != null) {
          propName = contract['kamar']['properti']['nama_properti'];
        }
      }
    }

    return TenantCrudModel(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      noHp: json['no_hp'] ?? '-',
      alamat: json['alamat'] ?? '-',
      fotoKtp: json['foto_ktp'],
      isActive: active,
      propertyName: propName,
      roomNumber: roomNo,
    );
  }

  String get ktpUrl {
    if (fotoKtp == null) return '';
    if (fotoKtp!.startsWith('http')) return fotoKtp!;
    return '${ApiConstants.baseUrl}$fotoKtp';
  }
}