import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/tenant_crud_model.dart';

// 1. STATE NOTIFIER (Logic CRUD)
class TenantCrudNotifier extends StateNotifier<AsyncValue<List<TenantCrudModel>>> {
  final Dio _dio; // Dio disuntikkan dari luar

  // Constructor Injection
  TenantCrudNotifier(this._dio) : super(const AsyncValue.loading()) {
    fetchTenants();
  }

  // GET ALL TENANTS
  Future<void> fetchTenants() async {
    try {
      // Hanya set loading jika data belum ada (agar tidak flickering saat refresh)
      if (state.value == null) state = const AsyncValue.loading();
      
      // Request simpel (Token & Base URL otomatis)
      final response = await _dio.get(
        '/user',
        queryParameters: {'role': 'PENYEWA'}, // Ambil hanya penyewa
      );

      final List data = response.data;
      state = AsyncValue.data(data.map((e) => TenantCrudModel.fromJson(e)).toList());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // ADD TENANT
  Future<bool> addTenant(String nama, String email, String hp, String alamat, String password) async {
    try {
      await _dio.post(
        '/user',
        data: {
          "nama": nama, "email": email, "no_hp": hp, 
          "alamat": alamat, "password": password
        },
      );
      await fetchTenants(); // Refresh list
      return true;
    } catch (e) {
      return false;
    }
  }

  // EDIT TENANT
  Future<bool> editTenant(int id, String nama, String email, String hp, String alamat, {String? password}) async {
    try {
      final data = {
        "nama": nama, "email": email, "no_hp": hp, "alamat": alamat
      };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      await _dio.put(
        '/user/$id',
        data: data,
      );
      await fetchTenants();
      return true;
    } catch (e) {
      return false;
    }
  }

  // DELETE TENANT
  Future<bool> deleteTenant(int id) async {
    try {
      await _dio.delete(
        '/user/$id',
      );
      await fetchTenants();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// 2. PROVIDER DEFINITION
final tenantCrudProvider = StateNotifierProvider<TenantCrudNotifier, AsyncValue<List<TenantCrudModel>>>((ref) {
  // Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);
  // Masukkan ke Notifier
  return TenantCrudNotifier(dio);
});