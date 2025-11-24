import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../admin/payments/models/payment_model.dart';
import '../providers/tenant_provider.dart';

class TenantHomeScreen extends ConsumerWidget {
  const TenantHomeScreen({super.key});

  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = (ref.watch(authProvider) as AuthAuthenticated).user;
    final billsAsync = ref.watch(myBillProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(myBillProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 20), // Padding vertikal saja
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER SAPAAN (Padding horizontal manual)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Halo, ${user.nama.split(' ')[0]} 👋", 
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("Selamat datang di kosmu", 
                            style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. LOGIC KARTU TAGIHAN (CAROUSEL)
                billsAsync.when(
                  loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
                  error: (err, _) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 150, 
                    color: Colors.red.shade50, 
                    child: Center(child: Text("Gagal muat tagihan: $err"))
                  ),
                  data: (bills) {
                    // Ambil SEMUA tagihan pending
                    final pendingBills = bills.where((b) => b.status == 'Pending').toList();

                    if (pendingBills.isNotEmpty) {
                      // --- KASUS 1: ADA TAGIHAN (TAMPILKAN CAROUSEL) ---
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "${pendingBills.length} Tagihan Menunggu",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // CAROUSEL WIDGET
                          SizedBox(
                            height: 260, // Tinggi area kartu
                            child: PageView.builder(
                              // viewportFraction: 0.9 membuat kartu di sebelahnya terlihat sedikit (hint scroll)
                              controller: PageController(viewportFraction: 1.0),
                              padEnds: false, // Mulai dari kiri
                              itemCount: pendingBills.length,
                              itemBuilder: (context, index) {
                                final bill = pendingBills[index];
                                // Bungkus dengan Padding agar ada jarak antar kartu
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12, left: 4), // Jarak antar kartu
                                  child: _buildPendingCard(context, bill),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // --- KASUS 2: TIDAK ADA TAGIHAN (KARTU HIJAU) ---
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Semua Lunas!",
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "Terima kasih sudah membayar tepat waktu.",
                                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 30),

                // 3. RIWAYAT PEMBAYARAN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Riwayat Pembayaran", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      billsAsync.when(
                        loading: () => const SizedBox(),
                        error: (e, _) => const SizedBox(),
                        data: (bills) {
                          final history = bills.where((b) => b.status != 'Pending').toList();

                          if (history.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text("Belum ada riwayat.", style: GoogleFonts.poppins(color: Colors.grey)),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final bill = history[index];
                              final isLunas = bill.status == 'Lunas';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isLunas ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isLunas ? Icons.check : Icons.close, 
                                      color: isLunas ? Colors.green : Colors.red
                                    ),
                                  ),
                                  title: Text("${bill.bulan} ${bill.tahun}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Text(bill.status, style: GoogleFonts.poppins(color: isLunas ? Colors.green : Colors.red)),
                                  trailing: Text(formatRupiah(bill.jumlah), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                ),
                              );
                            },
                          );
                        }
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET KARTU TAGIHAN ORANYE (DIPISAH AGAR RAPI)
  Widget _buildPendingCard(BuildContext context, PaymentModel bill) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Agar tombol selalu di bawah
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Jatuh Tempo", // Bisa diganti tanggal jatuh tempo real dari DB
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const Icon(Icons.priority_high, color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "${bill.bulan} ${bill.tahun}",
                style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 16),
              ),
              Text(
                formatRupiah(bill.jumlah),
                style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigasi ke Pembayaran untuk tagihan INI
                context.go('/tenant/home/payment', extra: bill);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
              child: Text("Bayar Sekarang", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}