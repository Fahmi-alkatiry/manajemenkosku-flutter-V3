import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/tenant_view_model.dart';

// Provider untuk mengambil List Penyewa Aktif (Berdasarkan Kontrak)
final adminTenantListProvider = FutureProvider.autoDispose<List<TenantViewModel>>((ref) async {
  // Ambil Dio Satpam (Otomatis Base URL & Token)
  final dio = ref.watch(dioClientProvider);

  // Kita ambil semua kontrak (bisa difilter status=AKTIF jika mau hanya yang aktif saja)
  final response = await dio.get(
    '/kontrak',
    // queryParameters: {'status': 'AKTIF'}, // Uncomment jika ingin memfilter
  );

  final List data = response.data;
  
  // Mapping JSON Kontrak menjadi List Penyewa
  return data.map((e) => TenantViewModel.fromContractJson(e)).toList();
});