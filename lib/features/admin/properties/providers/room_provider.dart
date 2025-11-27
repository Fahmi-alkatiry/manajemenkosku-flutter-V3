import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/room_model.dart';

// 1. STATE NOTIFIER (Logic CRUD Kamar)
class RoomNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  final Dio _dio; // Dio disuntikkan dari luar

  // Constructor Injection
  RoomNotifier(this._dio) : super(const AsyncValue.loading());

  // GET Rooms by Property ID
  Future<void> fetchRooms(String propertiId) async {
    try {
      // Set loading jika data belum ada
      if (state.value == null) state = const AsyncValue.loading();
      
      // Request simpel (Token & Base URL otomatis dihandle Interceptor)
      final response = await _dio.get('/kamar/properti/$propertiId');

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
      await _dio.post(
        '/kamar',
        data: {
          'propertiId': propertiId,
          'nomor_kamar': nomor,
          'tipe': tipe,
          'harga': harga,
          'deskripsi': desc,
        },
      );
      // Refresh list
      await fetchRooms(propertiId.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETE Room
  Future<bool> deleteRoom(int roomId, String propertiId) async {
    try {
      await _dio.delete(
        '/kamar/$roomId',
      );
      await fetchRooms(propertiId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // UPDATE Room
  Future<bool> updateRoom(int roomId, String propertiId, String nomor, String tipe, String harga, String desc) async {
    try {
      await _dio.put(
        '/kamar/$roomId',
        data: {
          'nomor_kamar': nomor,
          'tipe': tipe,
          'harga': harga,
          'deskripsi': desc,
        },
      );
      await fetchRooms(propertiId);
      return true;
    } catch(e) {
      return false;
    }
  }
}

// 2. PROVIDER GLOBAL
final roomProvider = StateNotifierProvider.family<RoomNotifier, AsyncValue<List<RoomModel>>, String>((ref, propertiId) {
  // Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);
  
  // Masukkan ke Notifier dan langsung fetch data
  return RoomNotifier(dio)..fetchRooms(propertiId);
});

// Provider untuk Detail 1 Kamar (Jika nanti dibutuhkan)
final singleRoomProvider = FutureProvider.family<RoomModel, int>((ref, roomId) async {
  // Kita siapkan strukturnya menggunakan Dio Client, 
  // meskipun logic-nya belum diimplementasi di backend atau UI.
  final dio = ref.watch(dioClientProvider);

  // Contoh jika nanti backend sudah ada:
  // final response = await dio.get('/kamar/$roomId');
  // return RoomModel.fromJson(response.data);
  
  throw UnimplementedError(); 
});