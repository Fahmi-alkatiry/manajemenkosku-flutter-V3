import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manajemen_kosku/core/constants/api_constants.dart';
import 'package:manajemen_kosku/core/services/storage_service.dart';
import '../models/room_model.dart';

// StateNotifier untuk mengelola list kamar
class RoomNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  final StorageService _storage = StorageService();
  final Dio _dio = Dio();

  RoomNotifier() : super(const AsyncValue.loading());

  // GET Rooms by Property ID
  Future<void> fetchRooms(String propertiId) async {
    try {
      state = const AsyncValue.loading();
      final token = await _storage.getToken();
      
      final response = await _dio.get(
        '${ApiConstants.apiUrl}/kamar/properti/$propertiId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List data = response.data;
      final rooms = data.map((e) => RoomModel.fromJson(e)).toList();
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // CREATE Room
  Future<bool> addRoom(int propertiId, String nomor, String tipe, String harga, String desc) async {
    try {
      final token = await _storage.getToken();
      await _dio.post(
        '${ApiConstants.apiUrl}/kamar',
        data: {
          'propertiId': propertiId,
          'nomor_kamar': nomor,
          'tipe': tipe,
          'harga': harga, // Nanti dikonversi jadi double di backend atau disini
          'deskripsi': desc,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Refresh
      await fetchRooms(propertiId.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETE Room
  Future<bool> deleteRoom(int roomId, String propertiId) async {
    try {
      final token = await _storage.getToken();
      await _dio.delete(
        '${ApiConstants.apiUrl}/kamar/$roomId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await fetchRooms(propertiId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Update Room (Opsional, untuk edit)
  Future<bool> updateRoom(int roomId, String propertiId, String nomor, String tipe, String harga, String desc) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/kamar/$roomId',
        data: {
          'nomor_kamar': nomor,
          'tipe': tipe,
          'harga': harga,
          'deskripsi': desc,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await fetchRooms(propertiId);
      return true;
    } catch(e) {
      return false;
    }
  }
}

// Provider Global
final roomProvider = StateNotifierProvider.family<RoomNotifier, AsyncValue<List<RoomModel>>, String>((ref, propertiId) {
  // .family memungkinkan kita membuat provider unik per properti ID
  return RoomNotifier()..fetchRooms(propertiId);
});


final singleRoomProvider = FutureProvider.family<RoomModel, int>((ref, roomId) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  // Kita gunakan endpoint GET /api/kamar/detail/:id (Pastikan backend ada atau gunakan logic list)
  // TAPI, karena backend Anda sepertinya belum punya endpoint spesifik "Get Single Room", 
  // Kita pakai trik: Panggil List Kamar by Properti, lalu filter di sini (Client side filtering).
  // Ini aman karena datanya sedikit.
  
  // Namun, untuk CreateContractScreen, kita sudah dikirim 'propertyId' dan 'kamarId'.
  // Jadi kita bisa ambil dari state 'roomProvider' yang sudah ada di memori jika sudah dimuat sebelumnya.
  
  // Cara paling bersih dan pasti jalan (tanpa ubah backend):
  // Kita tidak perlu call API baru. Kita cukup kirim data 'harga' lewat constructor screen saja.
  // TAPI, jika Anda ingin reload data fresh, kita bisa buat call API sederhana:
  
  // Mari kita asumsikan kita ambil fresh data agar aman:
  // (Catatan: Backend Anda di `kamar.routes.js` belum ada `router.get('/:id')` untuk detail 1 kamar.
  // Jadi kita akan memodifikasi `CreateContractScreen` untuk menerima parameter harga dari halaman sebelumnya saja.
  // Itu jauh lebih cepat dan efisien).
  
  throw UnimplementedError(); // Kita batalkan cara provider ini, kita pakai cara passing parameter saja.
});