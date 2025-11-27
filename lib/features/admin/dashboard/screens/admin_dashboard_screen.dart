import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Pastikan sudah 'flutter pub add intl'
import '../../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:manajemen_kosku/features/admin/dashboard/models/dashboard_model.dart';
import '../../payments/models/payment_model.dart'; // Import model Payment

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  // Helper Format Rupiah
  String formatRupiah(double number) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil User Info
    final user = (ref.watch(authProvider) as AuthAuthenticated).user;
    
    // 2. Ambil Data Dashboard dari API
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator( // Fitur Tarik ke Bawah untuk Refresh
          onRefresh: () async => ref.refresh(dashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard",
                        style: GoogleFonts.poppins(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Selamat datang kembali, ${user.nama}",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // 3. LOGIC: Tampilkan Loading / Error / Data
                dashboardAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text("Gagal memuat data: $error", textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => ref.refresh(dashboardProvider),
                          child: const Text("Coba Lagi"),
                        )
                      ],
                    ),
                  ),
                  data: (data) {
                    // DATA BERHASIL DIMUAT!
                    return Column(
                      children: [
                         /// Stats Grid
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                          children: [
                            StatCard(
                                icon: Icons.domain,
                                label: "Total Kamar",
                                value: "${data.rooms.total}",
                                color: Colors.blue),
                            StatCard(
                                icon: Icons.meeting_room,
                                label: "Kamar Terisi",
                                value: "${data.rooms.occupied}",
                                color: Colors.green),
                            StatCard(
                                icon: Icons.no_meeting_room,
                                label: "Kamar Kosong",
                                value: "${data.rooms.available}",
                                color: Colors.orange),
                            StatCard(
                                icon: Icons.access_time_filled,
                                label: "Tagihan Pending",
                                value: "${data.payments.pending}",
                                color: Colors.red),
                          ],
                        ),

                        const SizedBox(height: 24),

                        /// Revenue Banner (Bonus Visual untuk Total Pemasukan)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.lightBlueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Pemasukan (Lunas)", 
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                              Text(
                                formatRupiah(data.payments.totalRevenue),
                                style: GoogleFonts.poppins(
                                  color: Colors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// Title Pending Bills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              "Tagihan Menunggu Verifikasi",
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            if (data.payments.pending > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${data.payments.pending}",
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// List Tagihan (Dari API)
                        if (data.recentPendingPayments.isEmpty)
                           Padding(
                             padding: const EdgeInsets.all(20.0),
                             child: Text("Tidak ada tagihan pending.", style: GoogleFonts.poppins(color: Colors.grey)),
                           )
                        else
                          ...data.recentPendingPayments.map((bill) {
                            return _buildBillCard(context, bill, formatRupiah);
                          }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Kartu Tagihan yang dipisah agar rapi
  Widget _buildBillCard(BuildContext context, PendingPaymentItem bill, Function(double) formatter) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: InkWell(
       onTap: () {
           // KITA KONVERSI DATA DASHBOARD JADI PAYMENT MODEL
           // Agar bisa diterima oleh halaman Detail Verifikasi
           final payment = PaymentModel(
             id: bill.id,
             bulan: bill.bulan,
             tahun: bill.tahun,
             jumlah: bill.jumlah,
             status: bill.status,
             tenantName: bill.penyewaNama,
             roomNumber: bill.kamarNomor,
             // Data di bawah ini tidak tersedia di Dashboard (Lite), kita isi default/null
             contractId: 0, 
             buktiPembayaran: null, 
             tanggalJatuhTempo: null,
           );

           // Navigasi ke rute yang benar dengan membawa objek 'extra'
           context.go('/admin/verification/detail', extra: payment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.penyewaNama,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        "Kamar ${bill.kamarNomor}",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      bill.status,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatter(bill.jumlah), // Format Rp
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue),
                  ),
                  Text(
                    "${bill.bulan} ${bill.tahun}",
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// COMPONENT KARTU STATISTIK (Sama seperti sebelumnya)
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 28, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(label,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}