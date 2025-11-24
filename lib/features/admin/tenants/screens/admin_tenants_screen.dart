import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tenant_crud_provider.dart';
import '../models/tenant_crud_model.dart';

class AdminTenantsScreen extends ConsumerStatefulWidget {
  const AdminTenantsScreen({super.key});

  @override
  ConsumerState<AdminTenantsScreen> createState() => _AdminTenantsScreenState();
}

class _AdminTenantsScreenState extends ConsumerState<AdminTenantsScreen> {
  // State Lokal untuk Filter & Search
  String _searchQuery = "";
  String _selectedFilter = "Semua"; // Opsi: "Semua", "Aktif", "Non-Aktif"

  // --- LOGIC FORM & DELETE (Sama seperti sebelumnya) ---
  void _showFormDialog(BuildContext context, WidgetRef ref, {TenantCrudModel? tenant}) {
    final isEdit = tenant != null;
    final nameCtrl = TextEditingController(text: tenant?.nama ?? '');
    final emailCtrl = TextEditingController(text: tenant?.email ?? '');
    final phoneCtrl = TextEditingController(text: tenant?.noHp ?? '');
    final addressCtrl = TextEditingController(text: tenant?.alamat ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Penyewa" : "Tambah Penyewa Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.contains("@") ? null : "Email tidak valid",
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: "No. HP", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(labelText: "Alamat Asal", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? "Password Baru (Opsional)" : "Password",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: isEdit ? "Kosongkan jika tidak ingin mengubah" : null,
                  ),
                  validator: (v) => (!isEdit && v!.length < 6) ? "Min 6 karakter" : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                bool success;
                if (isEdit) {
                  success = await ref.read(tenantCrudProvider.notifier).editTenant(
                    tenant.id, nameCtrl.text, emailCtrl.text, phoneCtrl.text, addressCtrl.text, password: passCtrl.text
                  );
                } else {
                  success = await ref.read(tenantCrudProvider.notifier).addTenant(
                    nameCtrl.text, emailCtrl.text, phoneCtrl.text, addressCtrl.text, passCtrl.text
                  );
                }
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyimpan data")));
                }
              }
            },
            child: Text(isEdit ? "Simpan" : "Tambah"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Penyewa?"),
        content: const Text("Data yang dihapus tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(tenantCrudProvider.notifier).deleteTenant(id);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(tenantCrudProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, ref),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER FIXED (Agar tidak scroll)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: const Color(0xFFF5F7FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Judul
                  Text("Penyewa", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Kelola data penyewa dan status hunian", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
                  
                  const SizedBox(height: 16),

                  // 2. Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Cari nama penyewa...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. Filter Chips (Semua, Aktif, Non-Aktif)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("Semua"),
                        const SizedBox(width: 8),
                        _buildFilterChip("Aktif"),
                        const SizedBox(width: 8),
                        _buildFilterChip("Non-Aktif"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // LIST CONTENT
            Expanded(
              child: tenantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
                data: (tenants) {
                  // --- LOGIC FILTERING ---
                  final filteredList = tenants.where((t) {
                    // 1. Filter Status
                    bool matchesStatus = true;
                    if (_selectedFilter == "Aktif") matchesStatus = t.isActive;
                    if (_selectedFilter == "Non-Aktif") matchesStatus = !t.isActive;

                    // 2. Filter Search
                    bool matchesSearch = t.nama.toLowerCase().contains(_searchQuery) ||
                                         (t.propertyName?.toLowerCase().contains(_searchQuery) ?? false) ||
                                         (t.roomNumber?.toLowerCase().contains(_searchQuery) ?? false);

                    return matchesStatus && matchesSearch;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 50, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text("Data tidak ditemukan", style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final tenant = filteredList[index];
                      final isActive = tenant.isActive;

                      return GestureDetector(
                        onTap: () {
                          context.go('/admin/tenants/detail', extra: tenant);
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // AVATAR
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.person, size: 28, color: isActive ? Colors.blue : Colors.grey),
                                ),
                                const SizedBox(width: 12),

                                // CONTENT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Baris Nama & Status
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tenant.nama,
                                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: isActive ? Colors.green : Colors.grey),
                                              borderRadius: BorderRadius.circular(12),
                                              color: isActive ? Colors.green.withOpacity(0.05) : Colors.transparent
                                            ),
                                            child: Text(
                                              isActive ? "Aktif" : "Non-Aktif",
                                              style: GoogleFonts.poppins(fontSize: 10, color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 6),
                                      
                                      // Info HP
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(tenant.noHp, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Info Properti & Kamar (Hanya muncul jika aktif)
                                      if (isActive && tenant.propertyName != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.apartment, size: 14, color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "${tenant.propertyName} • Kamar ${tenant.roomNumber}",
                                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                                maxLines: 1, 
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (!isActive)
                                        Text("Tidak ada hunian aktif", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),

                                      const SizedBox(height: 12),
                                      const Divider(),

                                      // TOMBOL AKSI
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () => _showFormDialog(context, ref, tenant: tenant),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.edit, size: 16, color: Colors.blue),
                                                  const SizedBox(width: 4),
                                                  Text("Edit", style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          InkWell(
                                            onTap: () => _confirmDelete(context, ref, tenant.id),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete, size: 16, color: Colors.red),
                                                  const SizedBox(width: 4),
                                                  Text("Hapus", style: GoogleFonts.poppins(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Chip Filter
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }
}