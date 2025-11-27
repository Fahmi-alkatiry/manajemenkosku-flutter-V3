import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manajemen_kosku/core/constants/api_constants.dart';
import 'package:manajemen_kosku/core/services/storage_service.dart';
import '../models/dashboard_model.dart';
import '../../../../core/services/dio_client.dart';
// 1. Provider untuk mengambil data Dashboard (FutureProvider otomatis handle Loading/Error)
final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
 final dio = ref.watch(dioClientProvider);

  try {
   final response = await dio.get('/dashboard/admin');

    // Ubah JSON jadi Object Dart
    return DashboardModel.fromJson(response.data);
  } catch (e) {
    // Error handling standar
    throw Exception('Gagal memuat dashboard');
  }
});