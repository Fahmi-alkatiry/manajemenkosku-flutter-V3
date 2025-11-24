import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../payments/providers/payment_provider.dart';
import '../../payments/models/payment_model.dart';

class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data dari Provider (Status Pending)
    final paymentAsync = ref.watch(paymentListProvider('Pending'));

    return Scaffold(
      // FAB (Sesuai request desain Anda)
     floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           // Update Navigasi ke route yang baru kita buat
           context.go('/admin/verification/create'); 
        },
        label: const Text("Buat Tagihan"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Sesuai desain Anda)
              Text(
                "Verifikasi",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Tagihan menunggu verifikasi",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Pending Bills List (Dengan Data Real Riverpod)
              Expanded(
                child: paymentAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 60, color: Colors.green.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text("Tidak ada tagihan pending", style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return _buildPaymentCard(context, payment);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentModel payment) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Verifikasi (Membawa object payment)
        context.go('/admin/verification/detail', extra: payment);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon (Jam Oranye)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.access_time, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Atas: Nama Tenant & Badge Pending
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.tenantName,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Kamar ${payment.roomNumber}", // Data dinamis
                              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        // Badge Pending
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Pending",
                            style: GoogleFonts.poppins(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Baris Bawah: Jumlah & Metode/Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatRupiah(payment.jumlah),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue
                              ),
                            ),
                            Text(
                              "Transfer Bank", // Placeholder metode (karena belum ada di DB)
                              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          "${payment.bulan} ${payment.tahun}", // Data dinamis
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}