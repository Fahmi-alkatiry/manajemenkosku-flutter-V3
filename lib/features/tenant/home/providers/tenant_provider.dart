import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin/payments/models/payment_model.dart'; // Kita reuse model yang sudah ada
import '../../../../core/services/dio_client.dart';

// Provider untuk mengambil tagihan milik penyewa yang sedang login
final myBillProvider = FutureProvider.autoDispose<List<PaymentModel>>((ref) async {
  final dio = ref.watch(dioClientProvider);


  final response = await dio.get(
    '/pembayaran/saya',
  );

  final List data = response.data;
  return data.map((e) => PaymentModel.fromJson(e)).toList();
});