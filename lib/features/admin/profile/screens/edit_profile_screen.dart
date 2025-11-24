import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tenants/models/tenant_crud_model.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final TenantCrudModel user; // Data awal

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
    final success = await ref.read(profileServiceProvider).updateProfile(
      nama: _namaCtrl.text,
      noHp: _hpCtrl.text,
      alamat: _alamatCtrl.text,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui"), backgroundColor: Colors.green));
      ref.refresh(myProfileProvider); // Refresh data di halaman utama
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update profil"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
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
              decoration: const InputDecoration(labelText: "Alamat", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Simpan Perubahan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}