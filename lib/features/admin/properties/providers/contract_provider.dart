import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manajemen_kosku/core/constants/api_constants.dart';
import 'package:manajemen_kosku/core/services/storage_service.dart';
import '../models/tenant_model.dart';

// 1. PROVIDER: Ambil List Penyewa (Untuk Dropdown)
// Endpoint: GET /api/user?role=PENYEWA
final tenantListProvider = FutureProvider.autoDispose<List<TenantModel>>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/user', // Menggunakan endpoint user umum
    queryParameters: {'role': 'PENYEWA'}, // Filter via query param
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  return data.map((e) => TenantModel.fromJson(e)).toList();
});

// 2. SERVICE: Logic Membuat Kontrak
class ContractService {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  Future<bool> createContract({
    required int kamarId,
    required int penyewaId,
    required DateTime startDate,
    required DateTime endDate,
    required double harga,
  }) async {
    try {
      final token = await _storage.getToken();
      
      await _dio.post(
        '${ApiConstants.apiUrl}/kontrak',
        data: {
          "kamarId": kamarId,
          "penyewaId": penyewaId,
          "tanggal_mulai_sewa": startDate.toIso8601String(),
          "tanggal_akhir_sewa": endDate.toIso8601String(),
          "harga_sewa_disepakati": harga,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return true;
    } catch (e) {
      // print("Error create contract: $e");
      return false;
    }
  }

  Future<bool> endContract(int kontrakId) async {
    try {
      final token = await _storage.getToken();
      await _dio.put(
        '${ApiConstants.apiUrl}/kontrak/status/$kontrakId',
        data: {"status_kontrak": "BERAKHIR"},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final contractServiceProvider = Provider((ref) => ContractService());


class ContractDetailModel {
  final int id;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String roomNumber; // <--- TAMBAHAN FIELD
  
  ContractDetailModel({
    required this.id,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.roomNumber, // <--- TAMBAHAN
  });

  factory ContractDetailModel.fromJson(Map<String, dynamic> json) {
    return ContractDetailModel(
      id: json['id'],
      tenantName: json['penyewa']['nama'],
      tenantPhone: json['penyewa']['no_hp'] ?? '-',
      tenantEmail: json['penyewa']['email'],
      startDate: DateTime.parse(json['tanggal_mulai_sewa']),
      endDate: DateTime.parse(json['tanggal_akhir_sewa']),
      price: (json['harga_sewa_disepakati'] ?? 0).toDouble(),
      roomNumber: json['kamar']['nomor_kamar'] ?? '-', // <--- AMBIL DARI JSON
    );
  }
}

// 3. PROVIDER: Ambil Detail Kontrak Aktif by Kamar ID
final activeContractProvider = FutureProvider.autoDispose.family<ContractDetailModel, String>((ref, kamarId) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  final response = await dio.get(
    '${ApiConstants.apiUrl}/kontrak/active/kamar/$kamarId',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  return ContractDetailModel.fromJson(response.data);
});

class SimpleContractModel {
  final int id;
  final String tenantName;
  final String roomNumber;
  final String propertyName;
  final DateTime startDate;
  final DateTime endDate;
  // --- TAMBAHAN: List Tagihan yang sudah ada ---
  final List<Map<String, dynamic>> existingBills; 

  SimpleContractModel({
    required this.id,
    required this.tenantName,
    required this.roomNumber,
    required this.propertyName,
    required this.startDate,
    required this.endDate,
    required this.existingBills, // Masukkan ke constructor
  });

  factory SimpleContractModel.fromJson(Map<String, dynamic> json) {
    return SimpleContractModel(
      id: json['id'],
      tenantName: json['penyewa']['nama'] ?? 'Tanpa Nama',
      roomNumber: json['kamar']['nomor_kamar'] ?? '-',
      propertyName: json['kamar']['properti']['nama_properti'] ?? '-',
     startDate: DateTime.parse(json['tanggal_mulai_sewa']).toLocal(),
      endDate: DateTime.parse(json['tanggal_akhir_sewa']).toLocal(),
      // --- PARSING DATA PEMBAYARAN ---
      existingBills: List<Map<String, dynamic>>.from(
        (json['pembayaran'] ?? []).map((x) => {
          'bulan': x['bulan'],
          'tahun': x['tahun']
        })
      ),
    );
  }
}

// Provider untuk mengambil semua kontrak AKTIF (Buat Dropdown)
final activeContractsListProvider = FutureProvider.autoDispose<List<SimpleContractModel>>((ref) async {
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  // Panggil endpoint getAllKontrak dengan filter status=AKTIF
  final response = await dio.get(
    '${ApiConstants.apiUrl}/kontrak',
    queryParameters: {'status': 'AKTIF'}, 
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  return data.map((e) => SimpleContractModel.fromJson(e)).toList();
});