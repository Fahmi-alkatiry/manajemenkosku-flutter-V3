class TenantModel {
  final int id;
  final String nama;
  final String email;
  final String? noHp;

  TenantModel({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      noHp: json['no_hp'],
    );
  }
}