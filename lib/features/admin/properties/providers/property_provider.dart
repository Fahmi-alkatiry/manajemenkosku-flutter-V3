import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/property_model.dart';

// 1. STATE NOTIFIER (Logic CRUD)
class PropertyNotifier extends StateNotifier<AsyncValue<List<PropertyModel>>> {
  final Dio _dio; // Dio disuntikkan dari luar

  // Constructor Injection
  PropertyNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchProperties(); // Ambil data saat inisialisasi
  }

  // READ: Ambil semua properti
  Future<void> fetchProperties() async {
    try {
      // Tidak perlu set state loading lagi jika ini refresh background,
      // tapi untuk init awal biarkan loading.
      if (state.value == null) state = const AsyncValue.loading();
      
      // Request Simpel (Token & BaseURL otomatis)
      final response = await _dio.get('/properti');

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
      await _dio.post(
        '/properti',
        data: {'nama_properti': nama, 'alamat': alamat, 'deskripsi': desc},
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
      await _dio.put(
        '/properti/$id',
        data: {'nama_properti': nama, 'alamat': alamat, 'deskripsi': desc},
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
      await _dio.delete(
        '/properti/$id',
      );
      await fetchProperties();
      return true;
    } catch (e) {
      return false; 
    }
  }
}

// 2. DEFINISI PROVIDER
final propertyProvider = StateNotifierProvider<PropertyNotifier, AsyncValue<List<PropertyModel>>>((ref) {
  // Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);
  // Masukkan ke Notifier
  return PropertyNotifier(dio);
});

// Provider untuk ambil 1 Properti (Untuk Header Detail Screen)
final singlePropertyProvider = FutureProvider.family<PropertyModel, int>((ref, id) async {
  // Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);

  final response = await dio.get(
    '/properti/$id',
  );

  return PropertyModel.fromJson(response.data);
});