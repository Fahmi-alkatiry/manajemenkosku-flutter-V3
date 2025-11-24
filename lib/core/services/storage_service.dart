import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/user_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  // Simpan Token & User
  Future<void> saveAuthData(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // Simpan user object sebagai string JSON lengkap
    // Tambahkan token ke dalam user model agar tersimpan satu paket
    final userWithToken = UserModel(
      id: user.id, 
      nama: user.nama, 
      email: user.email, 
      role: user.role, 
      token: token
    );
    await prefs.setString(_userKey, jsonEncode(userWithToken.toJson()));
  }

  // Ambil User saat aplikasi baru dibuka
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return UserModel.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  // Hapus data saat Logout
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
  
  // Ambil token saja (untuk header request API nanti)
  Future<String?> getToken() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(_tokenKey);
  }
}