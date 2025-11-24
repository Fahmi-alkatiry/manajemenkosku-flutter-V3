import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../payments/models/payment_model.dart'; // Reuse model pembayaran

// 1. State untuk Filter Laporan (Menyimpan Bulan & Tahun yang dipilih)
class ReportFilterState {
  final String month;
  final int year;

  ReportFilterState({required this.month, required this.year});

  // Helper untuk membuat copy object dengan nilai baru
  ReportFilterState copyWith({String? month, int? year}) {
    return ReportFilterState(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

// 2. Notifier untuk Mengelola State Filter
class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(ReportFilterState(
    month: _getCurrentMonthName(), // Default bulan ini
    year: DateTime.now().year,     // Default tahun ini
  ));

  void setMonth(String month) {
    state = state.copyWith(month: month);
  }

  void setYear(int year) {
    state = state.copyWith(year: year);
  }

  // Helper ubah angka bulan ke nama
  static String _getCurrentMonthName() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[DateTime.now().month - 1];
  }
}

final reportFilterProvider = StateNotifierProvider<ReportFilterNotifier, ReportFilterState>((ref) {
  return ReportFilterNotifier();
});

// 3. Provider Utama: Ambil Data Laporan Berdasarkan Filter
// Provider ini "mendengarkan" (watch) reportFilterProvider.
// Jadi setiap kali filter berubah, provider ini otomatis fetch ulang data.
final reportListProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  // Ambil nilai filter saat ini
  final filter = ref.watch(reportFilterProvider);
  
  final dio = Dio();
  final storage = StorageService();
  final token = await storage.getToken();

  // Panggil API dengan parameter bulan & tahun
  final response = await dio.get(
    '${ApiConstants.apiUrl}/pembayaran',
    queryParameters: {
      'bulan': filter.month,
      'tahun': filter.year,
    },
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});

// 4. Provider Statistik (Opsional tapi bagus): Menghitung Total Pemasukan
// Ini menghitung data yang sudah diambil oleh reportListProvider tanpa fetch ulang
final reportStatsProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final reportAsync = ref.watch(reportListProvider);

  return reportAsync.when(
    data: (payments) {
      double totalRevenue = 0;
      int lunasCount = 0;
      int pendingCount = 0;
      int rejectedCount = 0;

      for (var p in payments) {
        if (p.status == 'Lunas') {
          totalRevenue += p.jumlah;
          lunasCount++;
        } else if (p.status == 'Pending') {
          pendingCount++;
        } else {
          rejectedCount++;
        }
      }

      return {
        'revenue': totalRevenue,
        'lunas': lunasCount,
        'pending': pendingCount,
        'rejected': rejectedCount,
        'total': payments.length
      };
    },
    loading: () => {'revenue': 0.0, 'lunas': 0, 'pending': 0, 'rejected': 0, 'total': 0},
    error: (_, __) => {'revenue': 0.0, 'lunas': 0, 'pending': 0, 'rejected': 0, 'total': 0},
  );
});