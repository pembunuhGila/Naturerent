import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/equipment.dart';
import '../models/rental_profile.dart';
import 'auth_service.dart';
import 'cart_service.dart';

enum ActivityOrderStatus {
  pending,
  confirmed,
  processing,
  rented,
  returned,
  completed,
  cancelled,
}

class ActivityOrder {
  final String id;
  final String nomorPesanan;
  final String namaRental;
  final double total;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final List<CartItem> items;
  final ActivityOrderStatus status;
  final DateTime createdAt;
  final String? paymentProofUrl;
  final Uint8List? paymentProofBytes;
  final String? cancellationReason;
  final String? cancellationNote;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationStatus;
  final String? refundProofUrl;
  final DateTime? refundUploadedAt;
  final String? refundStatus;

  const ActivityOrder({
    required this.id,
    required this.nomorPesanan,
    required this.namaRental,
    required this.total,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.items,
    required this.status,
    required this.createdAt,
    this.paymentProofUrl,
    this.paymentProofBytes,
    this.cancellationReason,
    this.cancellationNote,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationStatus,
    this.refundProofUrl,
    this.refundUploadedAt,
    this.refundStatus,
  });

  bool get dibatalkanPenyewa =>
      status == ActivityOrderStatus.cancelled && cancelledBy == 'user';

  ActivityOrder copyWith({
    ActivityOrderStatus? status,
    String? cancellationReason,
    String? cancellationNote,
    String? cancelledBy,
    DateTime? cancelledAt,
    String? cancellationStatus,
    String? refundProofUrl,
    DateTime? refundUploadedAt,
    String? refundStatus,
  }) {
    return ActivityOrder(
      id: id,
      nomorPesanan: nomorPesanan,
      namaRental: namaRental,
      total: total,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      items: items,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentProofUrl: paymentProofUrl,
      paymentProofBytes: paymentProofBytes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationNote: cancellationNote ?? this.cancellationNote,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationStatus: cancellationStatus ?? this.cancellationStatus,
      refundProofUrl: refundProofUrl ?? this.refundProofUrl,
      refundUploadedAt: refundUploadedAt ?? this.refundUploadedAt,
      refundStatus: refundStatus ?? this.refundStatus,
    );
  }
}

class RefundProofInfo {
  final String? proofUrl;
  final DateTime? uploadedAt;
  final String? status;

  const RefundProofInfo({this.proofUrl, this.uploadedAt, this.status});
}

class UserNotification {
  final String id;
  final String judul;
  final String pesan;
  final String? type;
  final String? refId;
  final bool isRead;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.createdAt,
    this.type,
    this.refId,
    this.isRead = false,
  });

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] as String,
      judul: map['judul'] as String? ?? 'Notifikasi',
      pesan: map['pesan'] as String? ?? '',
      type: map['type'] as String?,
      refId: map['ref_id'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  UserNotification copyWith({bool? isRead}) {
    return UserNotification(
      id: id,
      judul: judul,
      pesan: pesan,
      type: type,
      refId: refId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class OrderActivityService {
  factory OrderActivityService() => _instance;

  OrderActivityService._();

  static final OrderActivityService _instance = OrderActivityService._();

  final ValueNotifier<List<ActivityOrder>> orders =
      ValueNotifier<List<ActivityOrder>>(<ActivityOrder>[]);
  final ValueNotifier<List<UserNotification>> notifications =
      ValueNotifier<List<UserNotification>>(<UserNotification>[]);
  final ValueNotifier<int> unreadNotificationCount = ValueNotifier<int>(0);

  Future<void> muatNotifikasi() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) {
      notifications.value = <UserNotification>[];
      _syncUnreadNotificationCount();
      return;
    }

    try {
      final data = await AuthService.client
          .from('notifications')
          .select('id, judul, pesan, type, ref_id, is_read, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      notifications.value = (data as List)
          .whereType<Map<String, dynamic>>()
          .map(UserNotification.fromMap)
          .toList(growable: false);
      _syncUnreadNotificationCount();
    } catch (e) {
      debugPrint('Gagal memuat notifikasi: $e');
    }
  }

  Future<void> tandaiSemuaNotifikasiDibaca() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return;

    if (notifications.value.isEmpty) {
      await muatNotifikasi();
    }

    final unreadIds = notifications.value
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toList(growable: false);
    if (unreadIds.isEmpty) return;

    final success = await _updateNotifikasiTerbaca(
      userId: user.id,
      notificationIds: unreadIds,
    );
    if (!success) return;

    notifications.value = notifications.value
        .map(
          (notification) => unreadIds.contains(notification.id)
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList(growable: false);
    _syncUnreadNotificationCount();
  }

  Future<void> tandaiNotifikasiDibaca(String notificationId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null || notificationId.isEmpty) return;

    final success = await _updateNotifikasiTerbaca(
      userId: user.id,
      notificationIds: <String>[notificationId],
    );
    if (!success) return;

    notifications.value = notifications.value
        .map(
          (notification) => notification.id == notificationId
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList(growable: false);
    _syncUnreadNotificationCount();
  }

  Future<bool> _updateNotifikasiTerbaca({
    required String userId,
    required List<String> notificationIds,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      await AuthService.client
          .from('notifications')
          .update({'is_read': true, 'read_at': now})
          .eq('user_id', userId)
          .inFilter('id', notificationIds);
      return true;
    } on PostgrestException catch (e) {
      final missingReadAt =
          e.message.toLowerCase().contains('read_at') ||
          e.code == 'PGRST204' ||
          e.code == '42703';
      if (!missingReadAt) {
        debugPrint('Gagal menandai notifikasi terbaca: ${e.message}');
        return false;
      }

      try {
        await AuthService.client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId)
            .inFilter('id', notificationIds);
        return true;
      } catch (fallbackError) {
        debugPrint('Gagal menandai notifikasi terbaca: $fallbackError');
        return false;
      }
    } catch (e) {
      debugPrint('Gagal menandai notifikasi terbaca: $e');
      return false;
    }
  }

  void _syncUnreadNotificationCount() {
    unreadNotificationCount.value = notifications.value
        .where((notification) => !notification.isRead)
        .length;
  }

  Future<ActivityOrder> buatBookingDariKeranjang({
    required String namaRental,
    required double total,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required List<CartItem> items,
    required double biayaLayanan,
    required double taxRate,
    Uint8List? paymentProofBytes,
    String paymentProofExtension = 'jpg',
    String paymentProofContentType = 'image/jpeg',
    bool isDelivery = false,
    double deliveryFee = 0,
    Map<String, double>? deliveryFeesByRentalId,
    double? deliveryDistanceKm,
  }) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) throw Exception('Silakan login ulang sebelum membayar.');
    if (items.isEmpty) throw Exception('Keranjang kosong.');

    final paymentGroupId = _buatUuidV4();
    final nomorPesanan = _buatNomorPesanan();
    final proofUrl = paymentProofBytes == null
        ? null
        : await _preparePaymentProofValue(
            userId: user.id,
            paymentGroupId: paymentGroupId,
            bytes: paymentProofBytes,
            extension: paymentProofExtension,
            contentType: paymentProofContentType,
          );
    final durasi = _durasi(tanggalMulai, tanggalSelesai);
    final grouped = _groupByRental(items);
    final insertedRows = <Map<String, dynamic>>[];

    for (var i = 0; i < grouped.length; i++) {
      final group = grouped[i];
      final subtotal = group.subtotalPerHari * durasi;
      final groupDeliveryFee =
          deliveryFeesByRentalId?[group.rental.id] ??
          (i == 0 ? deliveryFee : 0);
      final data = await AuthService.client
          .from('bookings')
          .insert({
            'customer_id': user.id,
            'rental_id': group.rental.id,
            'tgl_mulai': _fmtDate(tanggalMulai),
            'tgl_selesai': _fmtDate(tanggalSelesai),
            'subtotal': subtotal,
            'tax_rate': taxRate,
            'biaya_layanan': i == 0 ? biayaLayanan : 0,
            'tipe_pengiriman': isDelivery ? 'delivery' : 'self_pickup',
            'biaya_kirim': isDelivery ? groupDeliveryFee : 0,
            'status': 'pending',
            'booking_code': nomorPesanan,
            'payment_group_id': paymentGroupId,
            'dp_percent': 0,
            'payment_method': 'qris',
            'payment_status': 'dp_under_review',
            'payment_proof_url': proofUrl,
            'catatan': isDelivery
                ? 'Bukti pembayaran lunas diupload melalui aplikasi NatureRent. '
                      'Delivery ${deliveryDistanceKm?.toStringAsFixed(1) ?? '-'} km.'
                : 'Bukti pembayaran lunas diupload melalui aplikasi NatureRent.',
          })
          .select('id, total_bayar')
          .single();

      final bookingId = data['id'] as String;
      insertedRows.add(data);

      await _buatPaymentLunas(
        bookingId: bookingId,
        jumlahBayar:
            subtotal +
            (i == 0 ? biayaLayanan : 0) +
            (isDelivery ? groupDeliveryFee : 0),
        proofUrl: proofUrl,
      );

      for (final item in group.items) {
        await AuthService.client.from('booking_items').insert({
          'booking_id': bookingId,
          'equipment_id': item.equipment.id,
          'rental_id': group.rental.id,
          'jumlah': item.qty,
          'harga_per_hari': item.equipment.hargaPerHari,
          'total_harga': item.equipment.hargaPerHari * item.qty * durasi,
          'nama_equipment': item.equipment.nama,
          'nama_rental': group.rental.namaRental,
        });
      }
    }

    await _buatNotifikasi(
      userId: user.id,
      refId: insertedRows.first['id'] as String,
      nomorPesanan: nomorPesanan,
    );

    final order = ActivityOrder(
      id: paymentGroupId,
      nomorPesanan: nomorPesanan,
      namaRental: namaRental,
      total: total,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      items: List<CartItem>.unmodifiable(items),
      status: ActivityOrderStatus.pending,
      createdAt: DateTime.now(),
      paymentProofUrl: proofUrl,
      paymentProofBytes: paymentProofBytes,
    );

    orders.value = <ActivityOrder>[order, ...orders.value];
    await muatDariDatabase();
    return order;
  }

  ActivityOrder tambahLokalPending({
    required String namaRental,
    required double total,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required List<CartItem> items,
    Uint8List? paymentProofBytes,
    String? paymentProofUrl,
  }) {
    final order = ActivityOrder(
      id: _buatUuidV4(),
      nomorPesanan: _buatNomorPesanan(),
      namaRental: namaRental,
      total: total,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      items: List<CartItem>.unmodifiable(items),
      status: ActivityOrderStatus.pending,
      createdAt: DateTime.now(),
      paymentProofUrl: paymentProofUrl,
      paymentProofBytes: paymentProofBytes,
    );

    orders.value = <ActivityOrder>[order, ...orders.value];
    return order;
  }

  Future<void> muatDariDatabase() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) {
      orders.value = <ActivityOrder>[];
      return;
    }

    try {
      final data = await AuthService.client
          .from('bookings')
          .select('''
            id,
            customer_id,
            rental_id,
            tgl_mulai,
            tgl_selesai,
            total_bayar,
            status,
            cancellation_reason,
            cancellation_note,
            cancelled_by,
            cancelled_at,
            cancellation_status,
            refund_uploaded_at,
            refund_status,
            booking_code,
            payment_group_id,
            created_at,
            rental_profiles(*, users!owner_id(nama_lengkap, email, no_wa), rental_settings(*)),
            booking_items(
              *,
              equipment(
                *,
                equipment_categories(nama, icon),
                rental_profiles(*, users!owner_id(nama_lengkap, email, no_wa), rental_settings(*)),
                equipment_images(image_url, is_primary, sort_order)
              )
            )
          ''')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(data as List);
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final key = (row['payment_group_id'] as String?) ?? row['id'] as String;
        grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(row);
      }

      orders.value = grouped.entries
          .map((entry) => _mapGroup(entry.key, entry.value))
          .toList(growable: false);
    } catch (e) {
      debugPrint('Gagal memuat aktivitas pesanan: $e');
      // Jika policy Supabase belum siap, pakai data lokal yang sudah ada.
    }
  }

  Future<String?> ambilBuktiPembayaran(String orderRefId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return null;

    final data = await AuthService.client
        .from('bookings')
        .select('payment_proof_url')
        .eq('customer_id', user.id)
        .or('payment_group_id.eq.$orderRefId,id.eq.$orderRefId')
        .not('payment_proof_url', 'is', null)
        .limit(1);

    final rows = List<Map<String, dynamic>>.from(data as List);
    if (rows.isEmpty) return null;
    final value = rows.first['payment_proof_url'] as String?;
    return value != null && value.trim().isNotEmpty ? value : null;
  }

  Future<RefundProofInfo?> ambilBuktiRefund(String orderRefId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return null;

    final data = await AuthService.client
        .from('bookings')
        .select('refund_proof_url, refund_uploaded_at, refund_status')
        .eq('customer_id', user.id)
        .or('payment_group_id.eq.$orderRefId,id.eq.$orderRefId')
        .not('refund_proof_url', 'is', null)
        .limit(1);

    final rows = List<Map<String, dynamic>>.from(data as List);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return RefundProofInfo(
      proofUrl: row['refund_proof_url'] as String?,
      uploadedAt: _parseOptionalDate(row['refund_uploaded_at']?.toString()),
      status: row['refund_status'] as String?,
    );
  }

  bool bisaDibatalkan(ActivityOrder order) {
    return order.status == ActivityOrderStatus.pending ||
        order.status == ActivityOrderStatus.confirmed ||
        order.status == ActivityOrderStatus.processing;
  }

  Future<void> batalkanPesananPenyewa({
    required String orderRefId,
    required String reason,
    String? note,
  }) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) throw Exception('Silakan login ulang.');

    final cleanedReason = reason.trim();
    final cleanedNote = note?.trim();
    if (cleanedReason.isEmpty) {
      throw Exception('Pilih alasan pembatalan terlebih dahulu.');
    }
    if (cleanedReason == 'Alasan lainnya' &&
        (cleanedNote == null || cleanedNote.isEmpty)) {
      throw Exception('Tuliskan alasan pembatalan.');
    }
    if (cleanedNote != null &&
        cleanedNote.isNotEmpty &&
        cleanedNote.length < 10) {
      throw Exception('Alasan pembatalan minimal 10 karakter.');
    }

    final rowsData = await AuthService.client
        .from('bookings')
        .select('id, status')
        .eq('customer_id', user.id)
        .or('payment_group_id.eq.$orderRefId,id.eq.$orderRefId');

    final rows = List<Map<String, dynamic>>.from(rowsData as List);
    if (rows.isEmpty) {
      throw Exception('Pesanan tidak ditemukan.');
    }

    const allowedStatuses = {'pending', 'confirmed', 'processing'};
    final cancellableIds = rows
        .where((row) => allowedStatuses.contains(row['status'] as String?))
        .map((row) => row['id'] as String)
        .toList(growable: false);

    if (cancellableIds.isEmpty) {
      throw Exception('Pesanan ini sudah tidak bisa dibatalkan.');
    }

    final cancelledAt = DateTime.now();
    await AuthService.client
        .from('bookings')
        .update({
          'status': 'cancelled',
          'cancellation_reason': cleanedReason,
          'cancellation_note': cleanedNote?.isEmpty == true
              ? null
              : cleanedNote,
          'cancelled_by': 'user',
          'cancelled_at': cancelledAt.toIso8601String(),
          'cancellation_status': 'Dibatalkan Penyewa',
          'updated_at': cancelledAt.toIso8601String(),
        })
        .inFilter('id', cancellableIds);

    orders.value = orders.value
        .map(
          (order) => order.id == orderRefId
              ? order.copyWith(
                  status: ActivityOrderStatus.cancelled,
                  cancellationReason: cleanedReason,
                  cancellationNote: cleanedNote,
                  cancelledBy: 'user',
                  cancelledAt: cancelledAt,
                  cancellationStatus: 'Dibatalkan Penyewa',
                )
              : order,
        )
        .toList(growable: false);

    await muatDariDatabase();
  }

  void ubahStatus(String id, ActivityOrderStatus status) {
    orders.value = orders.value
        .map((order) => order.id == id ? order.copyWith(status: status) : order)
        .toList(growable: false);
  }

  Future<void> _buatNotifikasi({
    required String userId,
    required String refId,
    required String nomorPesanan,
  }) async {
    try {
      await AuthService.client.from('notifications').insert({
        'user_id': userId,
        'judul': 'Pesanan #$nomorPesanan menunggu verifikasi',
        'pesan':
            'Bukti pembayaran lunas sudah diupload. Admin akan cek pembayaran '
            'lalu pemilik rental melakukan ACC.',
        'type': 'booking',
        'ref_id': refId,
      });
    } catch (_) {
      // Notifikasi bukan blocker untuk proses booking.
    }
  }

  Future<void> _buatPaymentLunas({
    required String bookingId,
    required double jumlahBayar,
    required String? proofUrl,
  }) async {
    try {
      await AuthService.client.from('payments').insert({
        'booking_id': bookingId,
        'jumlah_bayar': jumlahBayar,
        'status': 'paid',
        'qris_code_url': proofUrl,
        'tgl_bayar': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Table payments belum wajib untuk menampilkan riwayat user.
    }
  }

  ActivityOrder _mapGroup(String groupId, List<Map<String, dynamic>> rows) {
    final first = rows.first;
    final items = <CartItem>[];

    for (final booking in rows) {
      final bookingItems = List<Map<String, dynamic>>.from(
        booking['booking_items'] as List? ?? [],
      );
      final rentalMap = booking['rental_profiles'] as Map<String, dynamic>?;
      final rentalFallback = _rentalFromMap(
        rentalMap,
        booking['rental_id'] as String,
      );

      for (final item in bookingItems) {
        final equipmentMap = item['equipment'] as Map<String, dynamic>?;
        final rental = equipmentMap?['rental_profiles'] is Map<String, dynamic>
            ? _rentalFromMap(
                equipmentMap?['rental_profiles'] as Map<String, dynamic>?,
                item['rental_id'] as String? ?? rentalFallback.id,
              )
            : rentalFallback;

        final equipment = equipmentMap == null
            ? _equipmentFromSnapshot(item, rental.id)
            : Equipment.fromMap(equipmentMap);

        items.add(
          CartItem(
            equipment: equipment,
            rental: rental,
            qty: item['jumlah'] as int? ?? 1,
          ),
        );
      }
    }

    return ActivityOrder(
      id: groupId,
      nomorPesanan: (first['booking_code'] as String?) ?? _buatNomorPesanan(),
      namaRental: _namaRentalGroup(rows),
      total: rows.fold<double>(
        0,
        (sum, row) => sum + ((row['total_bayar'] as num?)?.toDouble() ?? 0),
      ),
      tanggalMulai: DateTime.parse(first['tgl_mulai'] as String),
      tanggalSelesai: DateTime.parse(first['tgl_selesai'] as String),
      items: List<CartItem>.unmodifiable(items),
      status: _statusGroup(rows),
      createdAt: DateTime.parse(first['created_at'] as String),
      cancellationReason: _firstNonEmpty(rows, 'cancellation_reason'),
      cancellationNote: _firstNonEmpty(rows, 'cancellation_note'),
      cancelledBy: _firstNonEmpty(rows, 'cancelled_by'),
      cancelledAt: _parseOptionalDate(_firstNonEmpty(rows, 'cancelled_at')),
      cancellationStatus: _firstNonEmpty(rows, 'cancellation_status'),
      refundProofUrl: null,
      refundUploadedAt: _parseOptionalDate(
        _firstNonEmpty(rows, 'refund_uploaded_at'),
      ),
      refundStatus: _firstNonEmpty(rows, 'refund_status'),
    );
  }

  String? _firstNonEmpty(List<Map<String, dynamic>> rows, String key) {
    for (final row in rows) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  DateTime? _parseOptionalDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<String> _uploadPaymentProof({
    required String userId,
    required String paymentGroupId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final safeExtension = switch (extension.toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      'jpg' || 'jpeg' => 'jpg',
      _ => 'jpg',
    };
    final path = '$userId/$paymentGroupId.$safeExtension';
    await AuthService.client.storage
        .from('payment-proofs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return AuthService.client.storage.from('payment-proofs').getPublicUrl(path);
  }

  Future<String> _preparePaymentProofValue({
    required String userId,
    required String paymentGroupId,
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    try {
      return await _uploadPaymentProof(
        userId: userId,
        paymentGroupId: paymentGroupId,
        bytes: bytes,
        extension: extension,
        contentType: contentType,
      );
    } catch (_) {
      return 'data:$contentType;base64,${base64Encode(bytes)}';
    }
  }

  RentalProfile _rentalFromMap(Map<String, dynamic>? map, String fallbackId) {
    if (map != null) return RentalProfile.fromMap(map);
    return RentalProfile(
      id: fallbackId,
      ownerId: '',
      namaRental: 'Rental',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Equipment _equipmentFromSnapshot(Map<String, dynamic> item, String rentalId) {
    return Equipment(
      id: item['equipment_id'] as String,
      rentalId: rentalId,
      nama: item['nama_equipment'] as String? ?? 'Alat Rental',
      hargaPerHari: (item['harga_per_hari'] as num?)?.toDouble() ?? 0,
      stock: 0,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      namaRental: item['nama_rental'] as String?,
    );
  }

  String _namaRentalGroup(List<Map<String, dynamic>> rows) {
    final names = rows
        .map((row) => row['rental_profiles'] as Map<String, dynamic>?)
        .map((rental) => rental?['nama_rental'] as String?)
        .whereType<String>()
        .toSet();
    if (names.length == 1) return names.first;
    return '${names.length} Toko Rental';
  }

  ActivityOrderStatus _statusGroup(List<Map<String, dynamic>> rows) {
    final statuses = rows
        .map((row) => row['status'] as String?)
        .whereType<String>()
        .map(_statusFromDb)
        .toList(growable: false);

    if (statuses.contains(ActivityOrderStatus.cancelled)) {
      return ActivityOrderStatus.cancelled;
    }
    if (statuses.contains(ActivityOrderStatus.pending)) {
      return ActivityOrderStatus.pending;
    }
    if (statuses.contains(ActivityOrderStatus.confirmed)) {
      return ActivityOrderStatus.confirmed;
    }
    if (statuses.contains(ActivityOrderStatus.processing)) {
      return ActivityOrderStatus.processing;
    }
    if (statuses.contains(ActivityOrderStatus.returned) ||
        statuses.contains(ActivityOrderStatus.completed)) {
      return ActivityOrderStatus.completed;
    }
    if (statuses.contains(ActivityOrderStatus.rented)) {
      return ActivityOrderStatus.rented;
    }
    return ActivityOrderStatus.completed;
  }

  ActivityOrderStatus _statusFromDb(String status) {
    return switch (status) {
      'confirmed' => ActivityOrderStatus.confirmed,
      'processing' => ActivityOrderStatus.processing,
      'rented' => ActivityOrderStatus.rented,
      'returned' => ActivityOrderStatus.returned,
      'completed' => ActivityOrderStatus.completed,
      'cancelled' => ActivityOrderStatus.cancelled,
      _ => ActivityOrderStatus.pending,
    };
  }

  List<CartRentalGroup> _groupByRental(List<CartItem> items) {
    final map = <String, List<CartItem>>{};
    final rentals = <String, RentalProfile>{};
    for (final item in items) {
      rentals[item.rental.id] = item.rental;
      map.putIfAbsent(item.rental.id, () => <CartItem>[]).add(item);
    }

    return map.entries
        .map(
          (entry) => CartRentalGroup(
            rental: rentals[entry.key]!,
            items: List<CartItem>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);
  }

  int _durasi(DateTime mulai, DateTime selesai) {
    final hari = selesai.difference(mulai).inDays;
    return hari <= 0 ? 1 : hari;
  }

  String _fmtDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _buatNomorPesanan() {
    final r = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(
      4,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
    final part2 = List.generate(
      2,
      (_) => chars[r.nextInt(chars.length)],
    ).join();
    return '$part1-$part2';
  }

  String _buatUuidV4() {
    final r = Random.secure();
    int b(int max) => r.nextInt(max);
    final bytes = List<int>.generate(16, (_) => b(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int n) => n.toRadixString(16).padLeft(2, '0');
    final s = bytes.map(hex).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
        '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }
}
