class UserModel {
  final int id;
  final String nama;
  final String email;
  final String role; // "ADMIN" atau "PENYEWA"
  final String? token; // Kita simpan token di sini untuk kemudahan akses

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.token,
  });

  // Factory untuk mengubah JSON dari Backend menjadi Object Dart
  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'],
      nama: json['nama'],
      email: json['email'],
      role: json['role'],
      token: token, // Token bisa disuntikkan terpisah atau dari JSON
    );
  }

  // Untuk menyimpan data user ke Shared Preferences (sebagai String JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role,
      'token': token,
    };
  }
}