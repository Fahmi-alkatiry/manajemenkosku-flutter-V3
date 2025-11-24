import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../models/payment_model.dart';
import 'dart:io'; // Wajib untuk File

// 1. PROVIDER: Ambil List Pembayaran (Bisa difilter status)
// Contoh penggunaan: ref.watch(paymentListProvider('Pending'))
final paymentListProvider = FutureProvider.autoDispose.family<List<PaymentModel>, String?>((ref, status) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/pembayaran', // Endpoint GET All Payment
    queryParameters: status != null ? {'status': status} : null,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});

// 2. SERVICE: Aksi (Konfirmasi & Buat Tagihan)
class PaymentService {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  // Konfirmasi: Lunas / Ditolak
  Future<bool> confirmPayment(int id, String status) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/pembayaran/konfirmasi/$id',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Buat Tagihan Baru (Manual)
  Future<bool> createBill(int kontrakId, String bulan, int tahun) async {
    try {
      final token = await _storage.getToken();
      await _dio.post(
        '${ApiConstants.apiUrl}/pembayaran',
        data: {
          'kontrakId': kontrakId,
          'bulan': bulan,
          'tahun': tahun
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadProof(int pembayaranId, File imageFile) async {
    try {
      final token = await _storage.getToken();
      
      // Siapkan nama file
      String fileName = imageFile.path.split('/').last;
      
      // Buat FormData
      FormData formData = FormData.fromMap({
        "bukti_pembayaran": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      await _dio.post(
        '${ApiConstants.apiUrl}/upload/bukti/$pembayaranId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // 'Content-Type': 'multipart/form-data' // Dio otomatis set ini
          },
        ),
      );
      
      return true;
    } catch (e) {
      // print("Upload Error: $e");
      return false;
    }
  }
}

final paymentServiceProvider = Provider((ref) => PaymentService());