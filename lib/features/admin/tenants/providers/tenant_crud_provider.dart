import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../models/tenant_crud_model.dart';

class TenantCrudNotifier extends StateNotifier<AsyncValue<List<TenantCrudModel>>> {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  TenantCrudNotifier() : super(const AsyncValue.loading()) {
    fetchTenants();
  }

  // GET ALL TENANTS
  Future<void> fetchTenants() async {
    try {
      final token = await _storage.getToken();
      final response = await _dio.get(
        '${ApiConstants.apiUrl}/user',
        queryParameters: {'role': 'PENYEWA'}, // Ambil hanya penyewa
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      final token = await _storage.getToken();
      await _dio.post(
        '${ApiConstants.apiUrl}/user',
        data: {
          "nama": nama, "email": email, "no_hp": hp, 
          "alamat": alamat, "password": password
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      final token = await _storage.getToken();
      final data = {
        "nama": nama, "email": email, "no_hp": hp, "alamat": alamat
      };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }

      await _dio.put(
        '${ApiConstants.apiUrl}/user/$id',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      final token = await _storage.getToken();
      await _dio.delete(
        '${ApiConstants.apiUrl}/user/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      await fetchTenants();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final tenantCrudProvider = StateNotifierProvider<TenantCrudNotifier, AsyncValue<List<TenantCrudModel>>>((ref) {
  return TenantCrudNotifier();
});