import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/contract_provider.dart';
import '../providers/room_provider.dart'; // Import RoomProvider untuk refresh data nanti
import '../models/tenant_model.dart';

class CreateContractScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String kamarId; // ID Kamar yang dipilih
  final double initialPrice; // <--- Parameter Harga dari halaman sebelumnya

  const CreateContractScreen({
    super.key,
    required this.propertyId,
    required this.kamarId,
    required this.initialPrice, 
  });

  @override
  ConsumerState<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends ConsumerState<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Input Controllers
  late TextEditingController _hargaController; // Gunakan late agar bisa di-init di initState
  
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedTenantId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // --- LOGIC AUTO-FILL HARGA ---
    // Mengonversi double (misal 1500000.0) menjadi String integer ("1500000")
    // agar tidak ada koma di text field.
    _hargaController = TextEditingController(text: widget.initialPrice.toInt().toString());
  }

  @override
  void dispose() {
    _hargaController.dispose();
    super.dispose();
  }

  // Helper Date Picker
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Otomatis set tanggal akhir + 1 bulan (UX friendly)
          if (_endDate == null) {
            _endDate = picked.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Fungsi Submit
  void _submitContract() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTenantId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih penyewa dahulu")));
        return;
      }
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi tanggal sewa")));
        return;
      }

      setState(() => _isLoading = true);

      // Panggil Service
      final success = await ref.read(contractServiceProvider).createContract(
        kamarId: int.parse(widget.kamarId),
        penyewaId: _selectedTenantId!,
        startDate: _startDate!,
        endDate: _endDate!,
        harga: double.parse(_hargaController.text.replaceAll(RegExp(r'[^0-9]'), '')), // Bersihkan format non-angka
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kontrak Berhasil Dibuat!"), backgroundColor: Colors.green),
        );
        
        // Refresh List Kamar di halaman sebelumnya agar status berubah jadi 'Ditempati'
        ref.refresh(roomProvider(widget.propertyId));

        // Kembali ke detail properti
        context.pop(); 
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuat kontrak"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil list penyewa dari provider
    final tenantListAsync = ref.watch(tenantListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Kontrak Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Informasi Sewa", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 1. DROPDOWN PENYEWA
              tenantListAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text("Gagal muat penyewa: $err", style: const TextStyle(color: Colors.red)),
                data: (tenants) {
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: "Pilih Penyewa",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    items: tenants.map((tenant) {
                      return DropdownMenuItem<int>(
                        value: tenant.id,
                        child: Text(tenant.nama, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTenantId = val);
                    },
                    validator: (val) => val == null ? "Wajib dipilih" : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. INPUT HARGA (Otomatis Terisi)
              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Harga Sewa (Per Bulan/Periode)",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                ),
                validator: (val) => val!.isEmpty ? "Harga wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // 3. INPUT TANGGAL (Row Start & End)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Mulai Sewa",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate != null ? DateFormat('dd MMM yyyy', 'id_ID').format(_startDate!) : "Pilih Tanggal",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Berakhir",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.event_busy),
                        ),
                        child: Text(
                          _endDate != null ? DateFormat('dd MMM yyyy', 'id_ID').format(_endDate!) : "Pilih Tanggal",
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitContract,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Buat Kontrak",
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}