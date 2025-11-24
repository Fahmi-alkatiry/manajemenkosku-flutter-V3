import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../admin/profile/providers/profile_provider.dart';

class TenantProfileScreen extends ConsumerStatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  ConsumerState<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends ConsumerState<TenantProfileScreen> {
  bool _isUploading = false;

  // Logic Upload KTP (Versi Aman)
  Future<void> _pickAndUploadKtp() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        final success = await ref.read(profileServiceProvider).uploadKtp(File(image.path));

        if (mounted) setState(() => _isUploading = false);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("KTP Berhasil diupload"), backgroundColor: Colors.green));
          ref.refresh(myProfileProvider);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal upload KTP"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memilih gambar"), backgroundColor: Colors.red));
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Profil Saya", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isUploading)
            const LinearProgressIndicator(color: Colors.orange, backgroundColor: Colors.white),

          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
              data: (user) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. HEADER
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.orange.shade50,
                              child: Text(
                                user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(user.nama, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(user.email, style: GoogleFonts.poppins(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text("PENYEWA", style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 2. MENU
                      _ProfileMenuTile(
                        icon: Icons.person_outline,
                        title: "Edit Data Diri",
                        subtitle: user.noHp,
                        onTap: () => context.go('/tenant/profile/edit', extra: user),
                      ),
                      _ProfileMenuTile(
                        icon: Icons.lock_outline,
                        title: "Ganti Password",
                        onTap: () => context.go('/tenant/profile/password'),
                      ),
                      _ProfileMenuTile(
                        icon: Icons.credit_card,
                        title: _isUploading ? "Mengupload..." : "Upload KTP",
                        subtitle: user.fotoKtp != null ? "KTP sudah tersimpan" : "Lengkapi identitas Anda",
                        iconColor: user.fotoKtp != null ? Colors.green : Colors.orange,
                        onTap: _isUploading ? () {} : _pickAndUploadKtp,
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
                        onTap: _showLogoutDialog,
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
  final Widget? trailingWidget;

  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor = Colors.black87,
    this.iconColor = Colors.orange,
    this.hideArrow = false,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)) : null,
      trailing: trailingWidget ?? (hideArrow ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)),
    );
  }
}