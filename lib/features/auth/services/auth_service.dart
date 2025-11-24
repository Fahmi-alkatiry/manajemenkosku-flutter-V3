import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart'; // Pastikan baseUrl ada di sini
import '../models/user_model.dart';

// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // URL: http://10.0.2.2:3000/api/auth/login
      final response = await _dio.post(
        '${ApiConstants.apiUrl}/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Jika sukses (Express mereturn 200)
      // Format backend Anda: { message: "...", token: "...", user: {...} }
      return response.data; 
    } on DioException catch (e) {
      // Tangkap error dari backend (misal 401 Password Salah)
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login Gagal');
      } else {
        throw Exception('Kesalahan koneksi: ${e.message}');
      }
    }
  }
}