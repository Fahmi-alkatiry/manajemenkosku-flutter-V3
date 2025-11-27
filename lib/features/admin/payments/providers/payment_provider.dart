import 'dart:io'; // Wajib untuk File
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/payment_model.dart';

// 1. PROVIDER: Ambil List Pembayaran
final paymentListProvider = FutureProvider.autoDispose.family<List<PaymentModel>, String?>((ref, status) async {
  // Ambil Dio yang sudah ada Interceptor (Token & BaseURL)
  final dio = ref.watch(dioClientProvider);

  final response = await dio.get(
    '/pembayaran', // Path relatif
    // PENTING: Masukkan status ke query params jika ada
    queryParameters: status != null ? {'status': status} : null, 
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});

// 2. SERVICE: Aksi (Konfirmasi & Buat Tagihan)
class PaymentService {
  final Dio _dio; // Dio diterima dari Provider

  // Constructor Injection
  PaymentService(this._dio);

  // Konfirmasi: Lunas / Ditolak
  Future<bool> confirmPayment(int id, String status) async {
    try {
      // Token otomatis disisipkan oleh Interceptor
      await _dio.put(
        '/pembayaran/konfirmasi/$id',
        data: {'status': status},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Buat Tagihan Baru (Manual)
  Future<bool> createBill(int kontrakId, String bulan, int tahun) async {
    try {
      await _dio.post(
        '/pembayaran',
        data: {
          'kontrakId': kontrakId,
          'bulan': bulan,
          'tahun': tahun
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload Bukti Bayar
  Future<bool> uploadProof(int pembayaranId, File imageFile) async {
    try {
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
        '/upload/bukti/$pembayaranId',
        data: formData,
        // Tidak perlu header token manual lagi
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

// 3. PROVIDER SERVICE
final paymentServiceProvider = Provider((ref) {
  // Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);
  // Masukkan ke Service
  return PaymentService(dio);
});