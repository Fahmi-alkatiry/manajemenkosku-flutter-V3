import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../../tenants/models/tenant_crud_model.dart'; 

// 1. PROVIDER: Ambil Data Profil Saya
final myProfileProvider = FutureProvider.autoDispose<TenantCrudModel>((ref) async {
  // Gunakan Dio yang sudah ada Interceptor-nya
  final dio = ref.watch(dioClientProvider);

  final response = await dio.get('/user/me'); // Cukup path relatif

  return TenantCrudModel.fromJson(response.data);
});

// 2. SERVICE: Logic Update, Ganti Pass, Upload
class ProfileService {
  final Dio _dio; // Dio diterima dari luar (via Provider)

  // Constructor: Kita paksa Service ini menerima Dio yang sudah "aman"
  ProfileService(this._dio);

  // Update Data Diri
  Future<bool> updateProfile({
    required String nama,
    required String noHp,
    required String alamat,
  }) async {
    try {
      // Tidak perlu ambil token manual lagi (sudah dihandle Interceptor)
      await _dio.put(
        '/user/me', // Path relatif saja
        data: {
          "nama": nama,
          "no_hp": noHp,
          "alamat": alamat,
        },
        // Tidak perlu options header manual lagi
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Ganti Password
  Future<bool> changePassword(String newPassword) async {
    try {
      await _dio.put(
        '/user/me',
        data: {"password": newPassword},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload Foto KTP
  Future<bool> uploadKtp(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        "foto_ktp": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      await _dio.post(
        '/upload/ktp',
        data: formData,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

// 3. DEFINISI PROVIDER SERVICE (PENTING!)
final profileServiceProvider = Provider((ref) {
  // A. Ambil Dio yang sudah ada satpamnya
  final dio = ref.watch(dioClientProvider);
  
  // B. Masukkan ke dalam Service
  return ProfileService(dio);
});