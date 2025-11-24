class DashboardModel {
  final RoomStats rooms;
  final TenantStats tenants;
  final PaymentStats payments;
  final List<PendingPaymentItem> recentPendingPayments;

  DashboardModel({
    required this.rooms,
    required this.tenants,
    required this.payments,
    required this.recentPendingPayments,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      rooms: RoomStats.fromJson(json['rooms']),
      tenants: TenantStats.fromJson(json['tenants']),
      payments: PaymentStats.fromJson(json['payments']),
      recentPendingPayments: (json['recentPendingPayments'] as List)
          .map((e) => PendingPaymentItem.fromJson(e))
          .toList(),
    );
  }
}

class RoomStats {
  final int total;
  final int occupied;
  final int available;

  RoomStats({required this.total, required this.occupied, required this.available});

  factory RoomStats.fromJson(Map<String, dynamic> json) {
    return RoomStats(
      total: json['total'] ?? 0,
      occupied: json['occupied'] ?? 0,
      available: json['available'] ?? 0,
    );
  }
}

class TenantStats {
  final int total;

  TenantStats({required this.total});

  factory TenantStats.fromJson(Map<String, dynamic> json) {
    return TenantStats(total: json['total'] ?? 0);
  }
}

class PaymentStats {
  final int pending;
  final double totalRevenue;

  PaymentStats({required this.pending, required this.totalRevenue});

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      pending: json['pending'] ?? 0,
      // Pastikan convert ke double karena prisma aggregate bisa return int/float
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}

class PendingPaymentItem {
  final int id;
  final double jumlah;
  final String bulan;
  final int tahun;
  final String status;
  final String penyewaNama;
  final String kamarNomor;

  PendingPaymentItem({
    required this.id,
    required this.jumlah,
    required this.bulan,
    required this.tahun,
    required this.status,
    required this.penyewaNama,
    required this.kamarNomor,
  });

  factory PendingPaymentItem.fromJson(Map<String, dynamic> json) {
    return PendingPaymentItem(
      id: json['id'],
      jumlah: (json['jumlah'] ?? 0).toDouble(),
      bulan: json['bulan'] ?? '',
      tahun: json['tahun'] ?? 0,
      status: json['status'] ?? 'Pending',
      penyewaNama: json['penyewaNama'] ?? 'Tanpa Nama',
      kamarNomor: json['kamarNomor'] ?? '-',
    );
  }
}