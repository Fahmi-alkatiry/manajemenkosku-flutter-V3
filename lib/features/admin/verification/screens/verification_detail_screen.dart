import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../payments/providers/payment_provider.dart';
import '../../payments/models/payment_model.dart';

class VerificationDetailScreen extends ConsumerStatefulWidget {
  final PaymentModel payment; // Terima data dari halaman sebelumnya

  const VerificationDetailScreen({super.key, required this.payment});

  @override
  ConsumerState<VerificationDetailScreen> createState() => _VerificationDetailScreenState();
}

class _VerificationDetailScreenState extends ConsumerState<VerificationDetailScreen> {
  bool _isLoading = false;

  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // --- LOGIC BACKEND (TETAP SAMA) ---
  void _processPayment(String status) async {
    setState(() => _isLoading = true);

    final success = await ref.read(paymentServiceProvider).confirmPayment(widget.payment.id, status);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'Lunas' ? "Pembayaran telah disetujui" : "Pembayaran telah ditolak"),
          backgroundColor: status == 'Lunas' ? Colors.green : Colors.red,
        )
      );
      // Refresh list pending
      ref.refresh(paymentListProvider('Pending'));
      context.pop(); // Kembali ke halaman sebelumnya
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memproses data"), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI WIDGET HELPERS ---
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final hasProof = payment.buktiPembayaran != null && payment.buktiPembayaran!.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    "Detail Verifikasi",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. BILL DETAILS CARD
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow(Icons.person, "Penyewa", payment.tenantName),
                      const SizedBox(height: 12),
                      _infoRow(Icons.apartment, "Properti & Kamar", "Kamar ${payment.roomNumber}"),
                      const SizedBox(height: 12),
                      // Gunakan Periode Bulan/Tahun karena createdAt belum ada di model
                      _infoRow(Icons.calendar_month, "Periode Tagihan", "${payment.bulan} ${payment.tahun}"), 
                      const SizedBox(height: 12),
                      _infoRow(Icons.credit_card, "Metode Pembayaran", "Transfer Bank"), // Placeholder
                      
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Pembayaran", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Text(
                            formatRupiah(payment.jumlah),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.blue
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. PAYMENT PROOF (BUKTI BAYAR)
              Text(
                "Bukti Pembayaran",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasProof
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            payment.fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                Text("Gagal memuat gambar ${payment.fullImageUrl}", style: GoogleFonts.poppins(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text("Tidak ada bukti transfer", style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text("Tolak", style: GoogleFonts.poppins(color: Colors.red)),
                      onPressed: _isLoading ? null : () => _processPayment('Ditolak'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(_isLoading ? "Proses..." : "Setujui", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                      onPressed: _isLoading ? null : () => _processPayment('Lunas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}