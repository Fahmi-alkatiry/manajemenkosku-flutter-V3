class TenantViewModel {
  final int tenantId;
  final String name;
  final String phone;
  final String roomNumber;
  final String propertyName;
  final String contractStatus;

  TenantViewModel({
    required this.tenantId,
    required this.name,
    required this.phone,
    required this.roomNumber,
    required this.propertyName,
    required this.contractStatus,
  });

  // Mapping dari JSON Kontrak
  factory TenantViewModel.fromContractJson(Map<String, dynamic> json) {
    return TenantViewModel(
      tenantId: json['penyewa']['id'] ?? 0, // Asumsi backend kirim ID penyewa di dalam objek penyewa
      name: json['penyewa']['nama'] ?? 'Tanpa Nama',
      phone: json['penyewa']['no_hp'] ?? '-',
      roomNumber: json['kamar']['nomor_kamar'] ?? '-',
      propertyName: json['kamar']['properti']['nama_properti'] ?? '-',
      contractStatus: json['status_kontrak'] ?? 'AKTIF',
    );
  }
}