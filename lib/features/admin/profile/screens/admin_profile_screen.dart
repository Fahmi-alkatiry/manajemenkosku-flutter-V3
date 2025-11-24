import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../tenants/models/tenant_crud_model.dart';

// 1. Ubah menjadi ConsumerStatefulWidget agar punya State
class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  // 2. Tambahkan variabel state untuk loading
  bool _isUploading = false;

  // --- LOGIC UPLOAD KTP (REVISI ANTI CRASH) ---
  Future<void> _pickAndUploadKtp(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Ambil gambar dengan resize agar ringan
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 50,
        maxWidth: 1000, 
        maxHeight: 1000,
      );

      if (image != null) {
        // A. Mulai Loading (Tanpa Dialog)
        setState(() => _isUploading = true);

        // B. Proses Upload
        final success = await ref.read(profileServiceProvider).uploadKtp(File(image.path));

        // C. Selesai Loading
        if (mounted) {
          setState(() => _isUploading = false);
        }

        // D. Tampilkan Hasil
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("KTP Berhasil diupload"), backgroundColor: Colors.green)
          );
          ref.refresh(myProfileProvider); // Refresh agar UI update
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal upload KTP"), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      // Tangkap error jika user membatalkan paksa atau HP kehabisan memori
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memilih gambar"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin keluar dari aplikasi?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Profil Saya", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      // Tampilkan Loading Bar di atas jika sedang upload
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(backgroundColor: Colors.blueAccent, color: Colors.white),
            
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Gagal memuat profil: $err")),
              data: (user) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 1. FOTO & NAMA
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?', 
                                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(user.nama, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(user.email, style: GoogleFonts.poppins(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text("ADMIN", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 2. MENU
                      _ProfileMenuTile(
                        icon: Icons.edit_outlined,
                        title: "Edit Data Diri",
                        subtitle: "${user.noHp} • ${user.alamat ?? '-'}",
                        onTap: () => context.go('/admin/profile/edit', extra: user),
                      ),
                      _ProfileMenuTile(
                        icon: Icons.lock_outline,
                        title: "Ganti Password",
                        onTap: () => context.go('/admin/profile/password'),
                      ),
                      
                      // MENU UPLOAD KTP (Dengan indikator loading)
                      _ProfileMenuTile(
                        icon: Icons.credit_card_outlined,
                        title: _isUploading ? "Sedang Mengupload..." : "Upload KTP",
                        subtitle: _isUploading 
                            ? "Mohon tunggu sebentar" 
                            : (user.fotoKtp != null ? "KTP sudah diupload" : "Verifikasi identitas Anda"),
                        iconColor: user.fotoKtp != null ? Colors.green : Colors.blueAccent,
                        // Matikan klik jika sedang uploading
                        onTap: _isUploading ? () {} : () => _pickAndUploadKtp(context),
                        trailingWidget: _isUploading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : null,
                      ),
                      
                      const Divider(height: 40),

                      // 3. LOGOUT
                      _ProfileMenuTile(
                        icon: Icons.logout,
                        title: "Keluar Aplikasi",
                        textColor: Colors.redAccent,
                        iconColor: Colors.redAccent,
                        hideArrow: true,
                        onTap: () => _showLogoutDialog(context),
                      ),
                      
                      const SizedBox(height: 20),
                      Text("Versi 1.0.0", style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color textColor;
  final Color iconColor;
  final bool hideArrow;
  final Widget? trailingWidget; // Tambahan untuk loading spinner custom

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor = Colors.black87,
    this.iconColor = Colors.blueAccent,
    this.hideArrow = false,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)) : null,
      trailing: trailingWidget ?? (hideArrow ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)),
    );
  }
}