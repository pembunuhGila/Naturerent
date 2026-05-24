import 'dart:math';

import 'package:flutter/foundation.dart';

import 'cart_service.dart';

enum ActivityOrderStatus {
  menungguAcc,
  aktif,
  selesai,
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
  });

  ActivityOrder copyWith({
    ActivityOrderStatus? status,
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
    );
  }
}

class OrderActivityService {
  factory OrderActivityService() => _instance;

  OrderActivityService._();

  static final OrderActivityService _instance = OrderActivityService._();

  final ValueNotifier<List<ActivityOrder>> orders =
      ValueNotifier<List<ActivityOrder>>(<ActivityOrder>[]);

  ActivityOrder tambahMenungguAcc({
    required String namaRental,
    required double total,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    required List<CartItem> items,
  }) {
    final order = ActivityOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nomorPesanan: _buatNomorPesanan(),
      namaRental: namaRental,
      total: total,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      items: List<CartItem>.unmodifiable(items),
      status: ActivityOrderStatus.menungguAcc,
      createdAt: DateTime.now(),
    );

    orders.value = <ActivityOrder>[order, ...orders.value];
    return order;
  }

  void ubahStatus(String id, ActivityOrderStatus status) {
    orders.value = orders.value
        .map((order) => order.id == id ? order.copyWith(status: status) : order)
        .toList(growable: false);
  }

  String _buatNomorPesanan() {
    final r = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    final part2 = List.generate(2, (_) => chars[r.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }
}
