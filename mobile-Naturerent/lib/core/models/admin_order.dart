class AdminOrderItem {
  final String namaEquipment;
  final int jumlah;
  final double totalHarga;
  final String? imageUrl;

  const AdminOrderItem({
    required this.namaEquipment,
    required this.jumlah,
    required this.totalHarga,
    this.imageUrl,
  });

  factory AdminOrderItem.fromMap(Map<String, dynamic> map) {
    final equipment = map['equipment'] as Map<String, dynamic>?;
    final images = List<Map<String, dynamic>>.from(
      equipment?['equipment_images'] as List? ?? const [],
    );
    String? imageUrl = equipment?['image_url'] as String?;
    if (images.isNotEmpty) {
      final primary = images.where((img) => img['is_primary'] == true);
      imageUrl ??= (primary.isNotEmpty ? primary.first : images.first)
          ['image_url'] as String?;
    }

    return AdminOrderItem(
      namaEquipment: map['nama_equipment'] as String? ?? 'Alat rental',
      jumlah: map['jumlah'] as int? ?? 1,
      totalHarga: (map['total_harga'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
    );
  }
}

class AdminOrder {
  final String id;
  final String? bookingCode;
  final String namaUser;
  final String namaRental;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final double totalBayar;
  final double commissionAmount;
  final double netToOwner;
  final String status;
  final String? paymentStatus;
  final String? paymentProofUrl;
  final String? cancellationReason;
  final String? cancellationNote;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationStatus;
  final DateTime createdAt;
  final List<AdminOrderItem> items;

  const AdminOrder({
    required this.id,
    this.bookingCode,
    required this.namaUser,
    required this.namaRental,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.totalBayar,
    required this.commissionAmount,
    required this.netToOwner,
    required this.status,
    this.paymentStatus,
    this.paymentProofUrl,
    this.cancellationReason,
    this.cancellationNote,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationStatus,
    required this.createdAt,
    required this.items,
  });

  bool get menungguAdmin => status == 'pending';
  bool get disetujuiAdmin => status == 'confirmed';
  bool get dibatalkanAdmin => status == 'cancelled';
  bool get dibatalkanPenyewa =>
      status == 'cancelled' && cancelledBy == 'user';
  bool get adaInfoPembatalan =>
      status == 'cancelled' &&
      ((cancellationReason?.trim().isNotEmpty ?? false) ||
          (cancellationNote?.trim().isNotEmpty ?? false) ||
          cancelledAt != null);
  bool get pembayaranLunas {
    final normalized = paymentStatus?.toLowerCase().trim();
    return normalized == 'lunas' ||
        normalized == 'paid' ||
        normalized == 'settled' ||
        normalized == 'success' ||
        normalized == 'dp_under_review' ||
        normalized == 'dp_confirmed';
  }

  String get statusPembayaranLabel =>
      pembayaranLunas
          ? 'Status Pembayaran: Lunas'
          : 'Status Pembayaran: Belum Dibayar';

  String get statusLabel {
    return switch (status) {
      'pending' => 'Menunggu Konfirmasi Admin',
      'confirmed' => 'Diteruskan ke Pemilik Rental',
      'processing' => 'Diproses Pemilik Rental',
      'rented' => 'Sedang Disewa',
      'returned' => 'Dikembalikan',
      'completed' => 'Selesai',
      'cancelled' =>
        cancellationStatus ??
        (dibatalkanPenyewa ? 'Dibatalkan Penyewa' : 'Dibatalkan Admin'),
      _ => status,
    };
  }

  String get ringkasanAlat {
    if (items.isEmpty) return 'Alat rental';
    final names = items.map((item) => item.namaEquipment).toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2} lainnya';
  }

  factory AdminOrder.fromMap(Map<String, dynamic> map) {
    final user = map['users'] as Map<String, dynamic>?;
    final rental = map['rental_profiles'] as Map<String, dynamic>?;
    final rawItems = List<Map<String, dynamic>>.from(
      map['booking_items'] as List? ?? const [],
    );
    String? namaRentalDariItem;
    for (final item in rawItems) {
      final value = item['nama_rental'] as String?;
      if (value != null && value.isNotEmpty) {
        namaRentalDariItem = value;
        break;
      }
    }

    return AdminOrder(
      id: map['id'] as String,
      bookingCode: map['booking_code'] as String?,
      namaUser:
          user?['nama_lengkap'] as String? ??
          user?['email'] as String? ??
          'Pengguna',
      namaRental:
          rental?['nama_rental'] as String? ??
          namaRentalDariItem ??
          'Rental',
      tanggalMulai: DateTime.parse(map['tgl_mulai'] as String),
      tanggalSelesai: DateTime.parse(map['tgl_selesai'] as String),
      totalBayar: (map['total_bayar'] as num?)?.toDouble() ?? 0,
      commissionAmount: (map['commission_amount'] as num?)?.toDouble() ?? 0,
      netToOwner: (map['net_to_owner'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      paymentStatus: map['payment_status'] as String?,
      paymentProofUrl: map['payment_proof_url'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      cancellationNote: map['cancellation_note'] as String?,
      cancelledBy: map['cancelled_by'] as String?,
      cancelledAt: _parseOptionalDate(map['cancelled_at']),
      cancellationStatus: map['cancellation_status'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: rawItems.map(AdminOrderItem.fromMap).toList(),
    );
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
