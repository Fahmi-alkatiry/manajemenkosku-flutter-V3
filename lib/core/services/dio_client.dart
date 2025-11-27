import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

// Provider untuk Dio Client yang sudah dipasangi "Satpam" (Interceptor)
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    }
  ));

  // PASANG INTERCEPTOR (SATPAM)
  dio.interceptors.add(InterceptorsWrapper(
    // 1. Sebelum Request: Selipkan Token otomatis
    onRequest: (options, handler) async {
      final storage = StorageService();
      final token = await storage.getToken();

      print("INTERCEPTOR CHECK: Token is $token");
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },

    // 2. Jika Error terjadi (Response datang dengan error)
    onError: (DioException e, handler) async {
      final statusCode = e.response?.statusCode;
      
      print("🚨 SERVER MESSAGE: ${e.response?.data}");
      // --- DEBUGGING: Lihat error apa yang sebenarnya terjadi ---
      print("INTERCEPTOR ERROR: Status Code = ${e.response?.statusCode}");
      
      // PERBAIKAN DI SINI:
      // Tangkap 401 (Unauthorized) DAN 403 (Forbidden)
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        
        print("Token Expired/Invalid: Melakukan Logout Paksa...");
        
        // Panggil fungsi logout
        ref.read(authProvider.notifier).logout();
      }
      
      return handler.next(e); 
    },
  ));

  return dio;
});