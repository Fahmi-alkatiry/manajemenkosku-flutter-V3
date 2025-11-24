import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manajemen_kosku/core/constants/api_constants.dart';
import 'package:manajemen_kosku/core/services/storage_service.dart';
import '../models/property_model.dart';

// 1. STATE NOTIFIER (Logic CRUD)
class PropertyNotifier extends StateNotifier<AsyncValue<List<PropertyModel>>> {
  final StorageService _storage = StorageService();
  final Dio _dio = Dio();

  PropertyNotifier() : super(const AsyncValue.loading()) {
    fetchProperties(); // Ambil data saat inisialisasi
  }

  // READ: Ambil semua properti
  Future<void> fetchProperties() async {
    try {
      state = const AsyncValue.loading();
      final token = await _storage.getToken();
      
      final response = await _dio.get(
        '${ApiConstants.apiUrl}/properti',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List data = response.data;
      final properties = data.map((e) => PropertyModel.fromJson(e)).toList();
      
      state = AsyncValue.data(properties);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // CREATE: Tambah properti baru
  Future<bool> addProperty(String nama, String alamat, String desc) async {
    try {
      final token = await _storage.getToken();
      await _dio.post(
        '${ApiConstants.apiUrl}/properti',
        data: {'nama_properti': nama, 'alamat': alamat, 'deskripsi': desc},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Refresh list setelah berhasil
      await fetchProperties();
      return true;
    } catch (e) {
      return false;
    }
  }

  // UPDATE: Edit properti
  Future<bool> updateProperty(int id, String nama, String alamat, String desc) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/properti/$id',
        data: {'nama_properti': nama, 'alamat': alamat, 'deskripsi': desc},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await fetchProperties();
      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETE: Hapus properti
  Future<bool> deleteProperty(int id) async {
    try {
      final token = await _storage.getToken();
      await _dio.delete(
        '${ApiConstants.apiUrl}/properti/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await fetchProperties();
      return true;
    } catch (e) {
      // Jika gagal (misal karena ada kamar), biasanya Dio melempar error 400/500
      return false; 
    }
  }
}

// 2. DEFINISI PROVIDER
final propertyProvider = StateNotifierProvider<PropertyNotifier, AsyncValue<List<PropertyModel>>>((ref) {
  return PropertyNotifier();
});

final singlePropertyProvider = FutureProvider.family<PropertyModel, int>((ref, id) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/properti/$id',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  return PropertyModel.fromJson(response.data);
});