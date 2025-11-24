import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/contract_provider.dart';
import '../providers/room_provider.dart';

class ActiveContractScreen extends ConsumerWidget {
  final String propertyId;
  final String kamarId;

  const ActiveContractScreen({
    super.key, 
    required this.propertyId, 
    required this.kamarId
  });

  // --- HELPER FUNCTIONS ---
  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }
  
  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Logic Akhiri Sewa (Backend)
  void _confirmEndContract(BuildContext context, WidgetRef ref, int kontrakId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Akhiri Sewa?"),
        content: const Text("Status kamar akan kembali menjadi 'Tersedia' dan kontrak selesai."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              final success = await ref.read(contractServiceProvider).endContract(kontrakId);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sewa berhasil diakhiri"), backgroundColor: Colors.green)
                );
                ref.refresh(roomProvider(propertyId)); // Refresh data kamar
                context.pop(); // Kembali
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gagal mengakhiri sewa"), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text("Akhiri Sewa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractAsync = ref.watch(activeContractProvider(kamarId));

    return Scaffold(
      body: SafeArea(
        child: contractAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Gagal memuat data: $err")),
          data: (contract) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Detail Kontrak Aktif",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. CONTRACT DETAILS CARD
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Status Kontrak", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Aktif",
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Penyewa
                          _buildInfoRow(
                            icon: Icons.person,
                            label: "Penyewa",
                            title: contract.tenantName,
                            subtitle: contract.tenantPhone,
                          ),
                          const SizedBox(height: 16),

                          // Properti & Kamar
                          _buildInfoRow(
                            icon: Icons.apartment,
                            label: "Kamar",
                            title: "Kamar ${contract.roomNumber}",
                            subtitle: "ID Properti: $propertyId", // Backend belum kirim nama properti di endpoint ini
                          ),
                          const SizedBox(height: 16),

                          // Periode Sewa
                          _buildInfoRow(
                            icon: Icons.calendar_month,
                            label: "Periode Sewa",
                            title: "${formatDate(contract.startDate)} - ${formatDate(contract.endDate)}",
                          ),
                          const SizedBox(height: 16),

                          // Harga Sewa
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: "Harga Sewa",
                            title: "${formatRupiah(contract.price)}/bulan",
                            titleColor: Colors.blue,
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Deposit (Hardcode/Placeholder karena DB belum ada)
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Deposit", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                                Text(formatRupiah(contract.price), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)), // Asumsi deposit 1 bulan
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // 3. ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmEndContract(context, ref, contract.id),
                      child: Text("Akhiri Sewa", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget Kecil untuk Baris Info (Agar kodenya rapi)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String title,
    String? subtitle,
    Color titleColor = Colors.black87,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align icon ke atas jika teks panjang
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
              Text(
                title, 
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor),
              ),
              if (subtitle != null)
                Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}