import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../providers/property_provider.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';
import '../models/property_model.dart'; // Pastikan import ini ada

class AdminPropertyDetailScreen extends ConsumerWidget {
  final String propertyId; // ID dari URL (String)

  const AdminPropertyDetailScreen({super.key, required this.propertyId});

  // --- HELPER FUNCTIONS ---

  String formatRupiah(double number) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return currencyFormatter.format(number);
  }

  // Logic Navigasi Klik Kamar
  void handleRoomClick(BuildContext context, RoomModel room) {
    if (room.status == 'Tersedia') {
      // Navigasi ke Buat Kontrak Baru
      context.go(
        Uri(
          path: '/admin/properties/detail/$propertyId/create-contract',
          queryParameters: {'roomId': room.id.toString(),
          'price': room.harga.toString()
          },
          
        ).toString()
      );
    } else {
      // Navigasi ke Detail Kontrak Aktif
     context.go(
        Uri(
          path: '/admin/properties/detail/$propertyId/active-contract',
          queryParameters: {'roomId': room.id.toString()},
        ).toString()
      );
    }
  }

  // Logic Hapus Kamar
  void _confirmDelete(BuildContext context, WidgetRef ref, int roomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Kamar?"),
        content: const Text("Data ini tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(roomProvider(propertyId).notifier).deleteRoom(roomId, propertyId);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Logic Show Form (Edit/Tambah) - Digunakan kembali
  void _showRoomForm(BuildContext context, WidgetRef ref, {RoomModel? room}) {
    final isEdit = room != null;
    final noCtrl = TextEditingController(text: room?.nomorKamar ?? '');
    final tipeCtrl = TextEditingController(text: room?.tipe ?? 'Standar');
    final hargaCtrl = TextEditingController(text: room != null ? room.harga.toInt().toString() : '');
    final descCtrl = TextEditingController(text: room?.deskripsi ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Edit Kamar' : 'Tambah Kamar Baru', 
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: noCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Kamar', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tipeCtrl,
                decoration: const InputDecoration(labelText: 'Tipe Kamar', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hargaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga per Bulan', prefixText: 'Rp ', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      bool success;
                      if (isEdit) {
                         success = await ref.read(roomProvider(propertyId).notifier).updateRoom(
                           room.id, propertyId, noCtrl.text, tipeCtrl.text, hargaCtrl.text, descCtrl.text
                         );
                      } else {
                         success = await ref.read(roomProvider(propertyId).notifier).addRoom(
                           int.parse(propertyId), noCtrl.text, tipeCtrl.text, hargaCtrl.text, descCtrl.text
                         );
                      }
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan")));
                      }
                    }
                  },
                  child: Text("Simpan", style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Logic Menu Custom (Sesuai Desain Anda)
  void showRoomMenu(BuildContext context, Offset tapPosition, RoomModel room, WidgetRef ref) {
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
          child: Text('Edit Kamar'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Hapus Kamar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showRoomForm(context, ref, room: room);
      } else if (value == 'delete') {
        _confirmDelete(context, ref, room.id);
      }
    });
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil List Kamar
    final roomState = ref.watch(roomProvider(propertyId));
    // 2. Ambil Detail Properti (untuk Header)
    final propertyState = ref.watch(singlePropertyProvider(int.parse(propertyId)));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
             // Refresh kedua provider
             ref.refresh(roomProvider(propertyId));
             ref.refresh(singlePropertyProvider(int.parse(propertyId)));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // HEADER SECTION (Dari Provider Properti)
                propertyState.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text("Gagal muat info: $e"),
                  data: (property) => Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(property.namaProperti,
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(property.alamat, 
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),

                // STATS SECTION (Dihitung dari RoomState)
                roomState.when(
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SizedBox(), // Error ditampilkan di list bawah saja
                  data: (rooms) {
                    final total = rooms.length;
                    final terisi = rooms.where((r) => r.status == 'Ditempati').length;

                    return Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text("Total Kamar", style: GoogleFonts.poppins(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text("$total", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text("Terisi", style: GoogleFonts.poppins(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text("$terisi", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 24),

                // ROOM LIST SECTION
                Text("Daftar Kamar", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                roomState.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (e, _) => Center(child: Text("Gagal memuat kamar: $e")),
                  data: (rooms) {
                    if (rooms.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(child: Text("Belum ada kamar.", style: GoogleFonts.poppins(color: Colors.grey))),
                      );
                    }

                    return Column(
                      children: rooms.map((room) {
                        final bool available = room.status == 'Tersedia';
                        
                        return GestureDetector(
                          onTap: () => handleRoomClick(context, room),
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // ICON STATUS
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: available ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      available ? Icons.door_front_door_outlined : Icons.meeting_room,
                                      color: available ? Colors.green : Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // INFO KAMAR
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Kamar ${room.nomorKamar}",
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            // MENU TITIK TIGA
                                            GestureDetector(
                                              onTapDown: (details) {
                                                showRoomMenu(context, details.globalPosition, room, ref);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                color: Colors.transparent, // Hit area
                                                child: const Icon(Icons.more_vert, size: 20),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        
                                        // TODO: Tampilkan Nama Penyewa jika backend sudah mendukung
                                        // if (!available)
                                        //   Text("Nama Penyewa", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                                        // const SizedBox(height: 4),

                                        Text("${formatRupiah(room.harga)}/bulan", 
                                          style: GoogleFonts.poppins(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: available ? Colors.green : Colors.grey),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            available ? "Tersedia" : "Ditempati",
                                            style: GoogleFonts.poppins(color: available ? Colors.green : Colors.grey, fontSize: 12),
                                          ),
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
                
                const SizedBox(height: 80), // Spacer untuk FAB
              ],
            ),
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoomForm(context, ref),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}