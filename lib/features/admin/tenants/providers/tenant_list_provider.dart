import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../models/tenant_view_model.dart';

// Provider untuk mengambil List Penyewa Aktif (Berdasarkan Kontrak)
final adminTenantListProvider = FutureProvider.autoDispose<List<TenantViewModel>>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  // Kita ambil semua kontrak (bisa difilter status=AKTIF jika mau hanya yang aktif saja)
  final response = await dio.get(
    '${ApiConstants.apiUrl}/kontrak',
    // queryParameters: {'status': 'AKTIF'}, 
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  
  // Mapping JSON Kontrak menjadi List Penyewa
  return data.map((e) => TenantViewModel.fromContractJson(e)).toList();
});