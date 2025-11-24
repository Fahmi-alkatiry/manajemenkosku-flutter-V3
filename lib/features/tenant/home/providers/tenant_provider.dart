import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../admin/payments/models/payment_model.dart'; // Kita reuse model yang sudah ada

// Provider untuk mengambil tagihan milik penyewa yang sedang login
final myBillProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/pembayaran/saya',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});