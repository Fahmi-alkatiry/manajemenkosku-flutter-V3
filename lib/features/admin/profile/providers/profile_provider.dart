import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../tenants/models/tenant_crud_model.dart'; // Kita reuse model user yang sudah ada

// 1. PROVIDER: Ambil Data Profil Saya (GET /api/user/me)
final myProfileProvider = FutureProvider.autoDispose<TenantCrudModel>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/user/me',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  return TenantCrudModel.fromJson(response.data);
});

// 2. SERVICE: Aksi (Update Profil, Ganti Password, Upload KTP)
class ProfileService {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  // Update Data Diri
  Future<bool> updateProfile({
    required String nama,
    required String noHp,
    required String alamat,
  }) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/user/me',
        data: {
          "nama": nama,
          "no_hp": noHp,
          "alamat": alamat,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Ganti Password
  Future<bool> changePassword(String newPassword) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/user/me',
        data: {"password": newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload Foto KTP
  Future<bool> uploadKtp(File imageFile) async {
    try {
      final token = await _storage.getToken();
      String fileName = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        "foto_ktp": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      await _dio.post(
        '${ApiConstants.apiUrl}/upload/ktp',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final profileServiceProvider = Provider((ref) => ProfileService());