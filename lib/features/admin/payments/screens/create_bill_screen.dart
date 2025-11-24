import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../properties/providers/contract_provider.dart';
import '../providers/payment_provider.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Data Form
  SimpleContractModel? _selectedContract;
  String? _selectedMonth;
  late int _selectedYear;

  // Daftar Nama Bulan
  final List<String> _allMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  // --- LOGIC PINTAR FILTER BULAN ---
  // --- LOGIC FILTER BULAN YANG LEBIH STABIL (VERSI YYYYMM) ---
  List<String> _getAvailableMonths() {
    if (_selectedContract == null) return [];

    List<String> validMonths = [];
    final alreadyBilledList = _selectedContract!.existingBills;

    // 1. Buat Format Angka untuk Start & End Kontrak (Contoh: 202512)
    // Rumus: (Tahun * 100) + Bulan
    int startCode = (_selectedContract!.startDate.year * 100) + _selectedContract!.startDate.month;
    int endCode = (_selectedContract!.endDate.year * 100) + _selectedContract!.endDate.month;

    for (int i = 0; i < 12; i++) {
      String monthName = _allMonths[i];
      int currentMonthNum = i + 1;
      
      // Kode Bulan yang sedang dicek (berdasarkan Tahun inputan)
      int checkCode = (_selectedYear * 100) + currentMonthNum;

      // 2. Cek Apakah Masuk Rentang? (Cukup bandingkan angka integernya)
      // Logika: checkCode harus >= startCode DAN checkCode <= endCode
      bool isWithinContract = (checkCode >= startCode) && (checkCode <= endCode);

      // 3. Cek Apakah Sudah Ditagih?
      bool isAlreadyBilled = alreadyBilledList.any((bill) => 
          bill['bulan'] == monthName && bill['tahun'] == _selectedYear
      );

      if (isWithinContract && !isAlreadyBilled) {
        validMonths.add(monthName);
      }
    }
    return validMonths;
  }

  void _submitBill() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedContract == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih kontrak penyewa dulu")));
        return;
      }
      if (_selectedMonth == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih bulan tagihan")));
        return;
      }

      setState(() => _isLoading = true);

      final success = await ref.read(paymentServiceProvider).createBill(
        _selectedContract!.id, 
        _selectedMonth!, 
        _selectedYear
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tagihan berhasil dibuat!"), backgroundColor: Colors.green),
        );
        ref.refresh(paymentListProvider('Pending'));
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuat tagihan"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(activeContractsListProvider);
    
    // Hitung bulan yang tersedia
    List<String> availableMonths = _getAvailableMonths();

    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Tagihan Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Penyewa (Kontrak Aktif)",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // 1. DROPDOWN KONTRAK (DIPERBAIKI)
              contractsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text("Error: $err", style: const TextStyle(color: Colors.red)),
                data: (contracts) {
                  if (contracts.isEmpty) {
                    return const Text("Tidak ada kontrak aktif.");
                  }
                  return DropdownButtonFormField<SimpleContractModel>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: const Text("Pilih Penyewa"),
                    value: _selectedContract,
                    isExpanded: true, // Agar menyesuaikan lebar
                    itemHeight: null, // PENTING: Agar item bisa multi-line (wrap)
                    items: contracts.map((contract) {
                      return DropdownMenuItem<SimpleContractModel>(
                        value: contract,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // PENTING: Agar tinggi seminimal mungkin
                            children: [
                              Text(contract.tenantName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              // Gunakan Flexible agar teks panjang turun ke bawah
                              Flexible(
                                child: Text(
                                  "${contract.propertyName} - Kamar ${contract.roomNumber}",
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    
                    onChanged: (val) {
                      setState(() {
                        _selectedContract = val;
                        _selectedMonth = null;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              Text(
                "Periode Tagihan",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // 2. ROW BULAN & TAHUN (DIPERBAIKI)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Tahun (Lebar lebih kecil)
                  Expanded(
                    flex: 3, // Proporsi 3
                    child: TextFormField(
                      initialValue: _selectedYear.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Tahun",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        helperText: "Ubah tahun...", // Helper text dipersingkat
                      ),
                      onChanged: (val) {
                        if (val.length == 4) {
                          setState(() {
                            _selectedYear = int.tryParse(val) ?? DateTime.now().year;
                            _selectedMonth = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Dropdown Bulan (Lebar lebih besar)
                  Expanded(
                    flex: 5, // Proporsi 5 (Lebih lebar untuk teks hint panjang)
                    child: DropdownButtonFormField<String>(
                      value: _selectedMonth,
                      isExpanded: true, // Mencegah overflow horizontal
                      decoration: InputDecoration(
                        labelText: "Bulan",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _selectedContract == null 
                          ? [] 
                          : availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: availableMonths.isEmpty ? null : (val) => setState(() => _selectedMonth = val!),
                      // Teks hint yang aman overflow
                      hint: Text(
                        _selectedContract == null 
                            ? "Pilih kontrak" 
                            : (availableMonths.isEmpty ? "Tidak ada jadwal" : "Pilih Bulan"),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      validator: (val) => val == null ? "Wajib diisi" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 3. TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Buat Tagihan",
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