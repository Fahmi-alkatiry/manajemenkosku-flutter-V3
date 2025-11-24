import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/property_provider.dart';
import '../models/property_model.dart';

class AdminPropertiesScreen extends ConsumerWidget {
  const AdminPropertiesScreen({super.key});

  // --- LOGIC FORM & DELETE (Tetap Sama dengan Sebelumnya) ---

  // Helper: Tampilkan Form (Tambah/Edit)
  void _showFormModal(BuildContext context, WidgetRef ref, {PropertyModel? property}) {
    final isEdit = property != null;
    final namaCtrl = TextEditingController(text: property?.namaProperti ?? '');
    final alamatCtrl = TextEditingController(text: property?.alamat ?? '');
    final deskripsiCtrl = TextEditingController(text: property?.deskripsi ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Properti' : 'Tambah Properti Baru',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kos / Kontrakan', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: alamatCtrl,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context); // Tutup modal
                      bool success;
                      if (isEdit) {
                        success = await ref.read(propertyProvider.notifier).updateProperty(
                          property.id, namaCtrl.text, alamatCtrl.text, deskripsiCtrl.text
                        );
                      } else {
                        success = await ref.read(propertyProvider.notifier).addProperty(
                          namaCtrl.text, alamatCtrl.text, deskripsiCtrl.text
                        );
                      }

                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Gagal menyimpan data"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Properti', 
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Dialog Konfirmasi Hapus
  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Properti?"),
        content: const Text("Data yang dihapus tidak bisa dikembalikan. Pastikan tidak ada kamar yang terdaftar di properti ini."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(propertyProvider.notifier).deleteProperty(id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Gagal menghapus (Mungkin masih ada kamar?)"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Helper Menu Custom (Sesuai Desain Anda)
  void showMenuAt(BuildContext context, Offset tapPosition, PropertyModel property, WidgetRef ref) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      tapPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')]),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))]),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showFormModal(context, ref, property: property);
      } else if (value == 'delete') {
        _confirmDelete(context, ref, property.id);
      }
    });
  }

  // --- UI UTAMA (Updated Layout) ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyState = ref.watch(propertyProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(propertyProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Sesuai Desain Baru)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Properti",
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Kelola properti Anda",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Content State (Loading/Error/Data)
                propertyState.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text("Error: $err")),
                  data: (properties) {
                    if (properties.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.home_work_outlined, size: 60, color: Colors.grey[300]),
                              Text("Belum ada properti", style: GoogleFonts.poppins(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    // List Properti (Iterasi Data Backend)
                    return Column(
                      children: properties.map((property) {
                        return GestureDetector(
                          onTap: () {
                             // Navigasi ke Detail Properti
                             context.go('/admin/properties/detail/${property.id}');
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Gedung Biru
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.apartment, color: Colors.blue, size: 24),
                                  ),
                                  const SizedBox(width: 12),

                                  // Detail Properti Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Baris Atas: Nama & Menu Button
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    property.namaProperti,
                                                    style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          property.alamat,
                                                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Menu Titik Tiga (Custom Position)
                                            GestureDetector(
                                              onTapDown: (details) {
                                                showMenuAt(context, details.globalPosition, property, ref);
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(Icons.more_vert, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),

                                        // Info Kamar Bawah
                                        Row(
                                          children: [
                                            // Total Kamar
                                            Row(
                                              children: [
                                                const Icon(Icons.meeting_room, size: 16, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "${property.jumlahKamar} kamar",
                                                  style: GoogleFonts.poppins(fontSize: 13),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                            
                                            // Kamar Terisi (SEKARANG SUDAH AKTIF)
                                            if (property.jumlahTerisi > 0) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1), // Background hijau muda
                                                  border: Border.all(color: Colors.green),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  "${property.jumlahTerisi} terisi",
                                                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            ] else ...[
                                               // Opsional: Jika kosong semua
                                               Text(
                                                  "Kosong",
                                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange),
                                                ),
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      // FAB (+ Button)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormModal(context, ref),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}