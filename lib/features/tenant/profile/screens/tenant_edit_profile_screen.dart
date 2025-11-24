import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../admin/profile/providers/profile_provider.dart'; // Reuse Provider
import '../../../admin/tenants/models/tenant_crud_model.dart'; // Reuse Model

class TenantEditProfileScreen extends ConsumerStatefulWidget {
  final TenantCrudModel user;

  const TenantEditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<TenantEditProfileScreen> createState() => _TenantEditProfileScreenState();
}

class _TenantEditProfileScreenState extends ConsumerState<TenantEditProfileScreen> {
  late TextEditingController _namaCtrl;
  late TextEditingController _hpCtrl;
  late TextEditingController _alamatCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.user.nama);
    _hpCtrl = TextEditingController(text: widget.user.noHp);
    _alamatCtrl = TextEditingController(text: widget.user.alamat ?? '');
  }

  void _save() async {
    setState(() => _isLoading = true);
    
    // Panggil Service yang sama dengan Admin
    final success = await ref.read(profileServiceProvider).updateProfile(
      nama: _namaCtrl.text,
      noHp: _hpCtrl.text,
      alamat: _alamatCtrl.text,
    );
    
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: Colors.green));
      ref.refresh(myProfileProvider); // Refresh data
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update profil"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Data Diri")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hpCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "No. Handphone", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamatCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Alamat Asal (Sesuai KTP)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), // Tema Oranye
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("Simpan Perubahan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}