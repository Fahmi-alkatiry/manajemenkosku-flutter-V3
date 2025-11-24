import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manajemen_kosku/core/constants/api_constants.dart';
import 'package:manajemen_kosku/core/services/storage_service.dart';
import '../models/dashboard_model.dart';

// 1. Provider untuk mengambil data Dashboard (FutureProvider otomatis handle Loading/Error)
final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  
  // Ambil token dari HP
  final token = await storage.getToken();

  try {
    final response = await dio.get(
      '${ApiConstants.apiUrl}/dashboard/admin', // Endpoint Backend Anda
      options: Options(
        headers: {
          'Authorization': 'Bearer $token', // Token Wajib untuk Middleware verifyToken
          'Content-Type': 'application/json',
        },
      ),
    );

    // Ubah JSON jadi Object Dart
    return DashboardModel.fromJson(response.data);
  } on DioException catch (e) {
    throw Exception(e.response?.data['message'] ?? 'Gagal memuat dashboard');
  }
});