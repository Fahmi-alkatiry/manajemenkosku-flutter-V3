import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/dio_client.dart'; // Import Dio Client Global
import '../../payments/models/payment_model.dart'; // Reuse model pembayaran

// 1. State untuk Filter Laporan (Tetap sama)
class ReportFilterState {
  final String month;
  final int year;

  ReportFilterState({required this.month, required this.year});

  ReportFilterState copyWith({String? month, int? year}) {
    return ReportFilterState(
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

// 2. Notifier untuk Mengelola State Filter (Tetap sama)
class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(ReportFilterState(
    month: _getCurrentMonthName(),
    year: DateTime.now().year,
  ));

  void setMonth(String month) {
    state = state.copyWith(month: month);
  }

  void setYear(int year) {
    state = state.copyWith(year: year);
  }

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

// 3. PROVIDER UTAMA (REFACTORED)
// Mengambil data menggunakan Dio Satpam
final reportListProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  // A. Ambil nilai filter saat ini
  final filter = ref.watch(reportFilterProvider);
  
  // B. Ambil Dio Satpam
  final dio = ref.watch(dioClientProvider);

  // C. Request Simpel (Token & URL otomatis)
  final response = await dio.get(
    '/pembayaran',
    queryParameters: {
      'bulan': filter.month,
      'tahun': filter.year,
    },
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});

// 4. Provider Statistik (Tetap sama - Logic murni)
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