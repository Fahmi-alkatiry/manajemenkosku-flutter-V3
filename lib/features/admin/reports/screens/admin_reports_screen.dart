import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/report_provider.dart';
import '../../payments/models/payment_model.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  // Helper Format Rupiah
  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Helper Warna Status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lunas': return Colors.green;
      case 'Pending': return Colors.orange;
      case 'Ditolak': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil State Filter (Bulan & Tahun yang sedang dipilih)
    final filterState = ref.watch(reportFilterProvider);
    
    // 2. Ambil Data Statistik (Total Pemasukan, Jumlah Transaksi)
    final stats = ref.watch(reportStatsProvider);
    
    // 3. Ambil List Transaksi
    final reportListAsync = ref.watch(reportListProvider);

    // Data Statis untuk Dropdown
    final List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final List<int> years = List.generate(5, (index) => DateTime.now().year - 2 + index); // 2023 s/d 2027

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu muda
      appBar: AppBar(
        title: Text("Laporan Keuangan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BAGIAN 1: FILTER & STATISTIK ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Row Filter Bulan & Tahun
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: filterState.month,
                        decoration: InputDecoration(
                          labelText: "Bulan",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) ref.read(reportFilterProvider.notifier).setMonth(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: filterState.year,
                        decoration: InputDecoration(
                          labelText: "Tahun",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                        onChanged: (val) {
                          if (val != null) ref.read(reportFilterProvider.notifier).setYear(val);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                // KARTU TOTAL PEMASUKAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Pemasukan (Lunas)",
                        style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      // Tampilkan Loading dummy jika list sedang loading, atau angka real
                      reportListAsync.isLoading
                          ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Colors.white))
                          : Text(
                              formatRupiah(stats['revenue']),
                              style: GoogleFonts.poppins(
                                color: Colors.white, 
                                fontSize: 28, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                      
                      const SizedBox(height: 16),
                      
                      // Statistik Kecil (Row)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(Icons.check_circle, "${stats['lunas']} Lunas", Colors.white),
                          _buildStatItem(Icons.access_time, "${stats['pending']} Pending", Colors.white.withOpacity(0.8)),
                          _buildStatItem(Icons.cancel, "${stats['rejected']} Ditolak", Colors.white.withOpacity(0.8)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- BAGIAN 2: LIST RIWAYAT ---
          Expanded(
            child: reportListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Gagal memuat data: $err")),
              data: (payments) {
                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text("Tidak ada transaksi periode ini", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildTransactionCard(payment);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Kecil untuk Statistik
  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Widget Kartu Transaksi List
  Widget _buildTransactionCard(PaymentModel payment) {
    final statusColor = _getStatusColor(payment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // Flat style agar tidak terlalu ramai
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12)
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon Status
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                payment.status == 'Lunas' ? Icons.arrow_downward : Icons.priority_high,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Utama
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.tenantName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Kamar ${payment.roomNumber}",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Jumlah & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(payment.jumlah),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.status,
                    style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}