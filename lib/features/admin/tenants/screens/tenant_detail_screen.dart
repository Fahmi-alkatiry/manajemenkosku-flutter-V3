import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tenant_crud_model.dart';

class TenantDetailScreen extends StatelessWidget {
  final TenantCrudModel tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    final bool hasKtp = tenant.fotoKtp != null && tenant.fotoKtp!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Penyewa")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Info Utama
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(tenant.nama[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Text(tenant.nama, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(tenant.email, style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Data Detail
            _detailItem(Icons.phone, "No. Handphone", tenant.noHp),
            const Divider(),
            _detailItem(Icons.location_on, "Alamat Asal", tenant.alamat ?? '-'),
            const Divider(),
            
            const SizedBox(height: 24),

            // 3. Foto KTP (Fitur yang diminta)
            Text("Foto KTP", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: hasKtp
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        tenant.ktpUrl, // URL dari Model
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => const Center(child: Text("Gagal memuat foto KTP")),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text("Belum ada foto KTP", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}