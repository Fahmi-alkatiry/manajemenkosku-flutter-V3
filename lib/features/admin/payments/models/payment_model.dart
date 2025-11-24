import '../../../../core/constants/api_constants.dart';

class PaymentModel {
  final int id;
  final String bulan;
  final int tahun;
  final double jumlah;
  final String status; // Pending, Lunas, Ditolak
  final String? buktiPembayaran; // URL Gambar
  final DateTime? tanggalJatuhTempo;
  
  // Data Relasi (Flattened agar mudah diakses di UI)
  final String tenantName;
  final String roomNumber;
  final int contractId;

  PaymentModel({
    required this.id,
    required this.bulan,
    required this.tahun,
    required this.jumlah,
    required this.status,
    this.buktiPembayaran,
    this.tanggalJatuhTempo,
    required this.tenantName,
    required this.roomNumber,
    required this.contractId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengambil data bersarang dengan aman
    final kontrak = json['kontrak'] ?? {};
    final penyewa = kontrak['penyewa'] ?? {};
    final kamar = kontrak['kamar'] ?? {};

    return PaymentModel(
      id: json['id'],
      bulan: json['bulan'],
      tahun: json['tahun'],
      jumlah: (json['jumlah'] ?? 0).toDouble(),
      status: json['status'],
      // Jika ada bukti bayar, tambahkan Base URL agar bisa diload Image.network
      buktiPembayaran: json['bukti_pembayaran'], 
      tanggalJatuhTempo: json['tanggal_jatuh_tempo'] != null 
          ? DateTime.parse(json['tanggal_jatuh_tempo']) 
          : null,
      tenantName: penyewa['nama'] ?? 'Tanpa Nama',
      roomNumber: kamar['nomor_kamar'] ?? '-',
      contractId: json['kontrakId'] ?? 0,
    );
  }
  
  // Helper untuk mendapatkan URL gambar lengkap
  String get fullImageUrl {
    if (buktiPembayaran == null) return '';
    if (buktiPembayaran!.startsWith('http')) return buktiPembayaran!;
    return '${ApiConstants.baseUrl}$buktiPembayaran';
  }
}