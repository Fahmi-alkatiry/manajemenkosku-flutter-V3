import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../models/tenant_model.dart';

// 1. PROVIDER: Ambil List Penyewa (Untuk Dropdown)
// Endpoint: GET /api/user?role=PENYEWA
final tenantListProvider = FutureProvider.autoDispose<List<TenantModel>>((ref) async {
  // Gunakan Dio Satpam
  final dio = ref.watch(dioClientProvider);

  final response = await dio.get(
    '/user', // Path relatif
    queryParameters: {'role': 'PENYEWA'},
    // Tidak perlu header manual lagi
  );

  final List data = response.data;
  return data.map((e) => TenantModel.fromJson(e)).toList();
});

// 2. SERVICE: Logic Membuat & Mengakhiri Kontrak
class ContractService {
  final Dio _dio; // Dio disuntikkan dari luar

  // Constructor Injection
  ContractService(this._dio);

  Future<bool> createContract({
    required int kamarId,
    required int penyewaId,
    required DateTime startDate,
    required DateTime endDate,
    required double harga,
  }) async {
    try {
      await _dio.post(
        '/kontrak',
        data: {
          "kamarId": kamarId,
          "penyewaId": penyewaId,
          "tanggal_mulai_sewa": startDate.toIso8601String(),
          "tanggal_akhir_sewa": endDate.toIso8601String(),
          "harga_sewa_disepakati": harga,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endContract(int kontrakId) async {
    try {
      await _dio.put(
        '/kontrak/status/$kontrakId',
        data: {"status_kontrak": "BERAKHIR"},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider Service (Inject Dio)
final contractServiceProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider);
  return ContractService(dio);
});

// --- MODEL (Tetap Sama) ---

class ContractDetailModel {
  final int id;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String roomNumber; 
  
  ContractDetailModel({
    required this.id,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.roomNumber, 
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
      roomNumber: json['kamar']['nomor_kamar'] ?? '-', 
    );
  }
}

// 3. PROVIDER: Ambil Detail Kontrak Aktif by Kamar ID
final activeContractProvider = FutureProvider.autoDispose.family<ContractDetailModel, String>((ref, kamarId) async {
  final dio = ref.watch(dioClientProvider);

  final response = await dio.get(
    '/kontrak/active/kamar/$kamarId',
  );

  return ContractDetailModel.fromJson(response.data);
});

// --- MODEL DROPDOWN (Tetap Sama) ---

class SimpleContractModel {
  final int id;
  final String tenantName;
  final String roomNumber;
  final String propertyName;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> existingBills; 

  SimpleContractModel({
    required this.id,
    required this.tenantName,
    required this.roomNumber,
    required this.propertyName,
    required this.startDate,
    required this.endDate,
    required this.existingBills, 
  });

  factory SimpleContractModel.fromJson(Map<String, dynamic> json) {
    return SimpleContractModel(
      id: json['id'],
      tenantName: json['penyewa']['nama'] ?? 'Tanpa Nama',
      roomNumber: json['kamar']['nomor_kamar'] ?? '-',
      propertyName: json['kamar']['properti']['nama_properti'] ?? '-',
      startDate: DateTime.parse(json['tanggal_mulai_sewa']).toLocal(),
      endDate: DateTime.parse(json['tanggal_akhir_sewa']).toLocal(),
      existingBills: List<Map<String, dynamic>>.from(
        (json['pembayaran'] ?? []).map((x) => {
          'bulan': x['bulan'],
          'tahun': x['tahun'],
          'status': x['status']
        })
      ),
    );
  }
}

// Provider untuk mengambil semua kontrak AKTIF (Buat Dropdown)
final activeContractsListProvider = FutureProvider.autoDispose<List<SimpleContractModel>>((ref) async {
  final dio = ref.watch(dioClientProvider);

  // Panggil endpoint getAllKontrak dengan filter status=AKTIF
  final response = await dio.get(
    '/kontrak',
    queryParameters: {'status': 'AKTIF'}, 
  );

  final List data = response.data;
  return data.map((e) => SimpleContractModel.fromJson(e)).toList();
});