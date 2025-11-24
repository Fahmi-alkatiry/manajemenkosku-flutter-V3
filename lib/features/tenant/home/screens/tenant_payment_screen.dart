import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../admin/payments/models/payment_model.dart';
import '../../../admin/payments/providers/payment_provider.dart';
import '../providers/tenant_provider.dart'; // Untuk refresh home

class TenantPaymentScreen extends ConsumerStatefulWidget {
  final PaymentModel bill; // Data tagihan yang dikirim dari Home

  const TenantPaymentScreen({super.key, required this.bill});

  @override
  ConsumerState<TenantPaymentScreen> createState() => _TenantPaymentScreenState();
}

class _TenantPaymentScreenState extends ConsumerState<TenantPaymentScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Fungsi Format Rupiah
  String formatRupiah(double number) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Fungsi Pilih Gambar
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50); // Kompres 50% biar ringan
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  // Fungsi Upload
  void _submitProof() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    final success = await ref.read(paymentServiceProvider).uploadProof(
      widget.bill.id, 
      _selectedImage!
    );

    setState(() => _isUploading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bukti berhasil diupload! Menunggu verifikasi."), backgroundColor: Colors.green),
      );
      
      // Refresh data di Home agar kartu oranye hilang/berubah status
      ref.refresh(myBillProvider);
      
      // Kembali ke Home
      context.pop(); 
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal upload bukti. Coba lagi."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Konfirmasi Pembayaran", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Info Jumlah Tagihan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text("Total Pembayaran", style: GoogleFonts.poppins(color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(widget.bill.jumlah),
                    style: GoogleFonts.poppins(
                      fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blueAccent
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${widget.bill.bulan} ${widget.bill.tahun}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Info Rekening (Hardcode Sederhana)
            Text("Transfer ke:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Logo Bank (Icon dummy)
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text("BCA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("1234-5678-9000", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      Text("a.n. Pemilik Kos", style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Upload Bukti
            Text("Upload Bukti Transfer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text("Ketuk untuk pilih gambar", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Ganti Gambar"),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // 4. Tombol Kirim
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedImage == null || _isUploading) ? null : _submitProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("Kirim Bukti Pembayaran", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}