import 'package:flutter/material.dart';

/// Model data destinasi wisata untuk halaman Owner.
/// [lat] dan [lng] bersifat opsional — destinasi tanpa koordinat
/// tetap aman digunakan dan tidak menyebabkan error.
class DestinationInfo {
  final String? id;
  final String title;
  final String distance;
  final String detailDistance;
  final IconData icon;
  final Color color;

  /// Koordinat opsional (bisa null jika data GPS belum tersedia)
  final double? lat;
  final double? lng;

  const DestinationInfo({
    this.id,
    required this.title,
    required this.distance,
    required this.detailDistance,
    required this.icon,
    required this.color,
    this.lat,
    this.lng,
  });

  /// Buat salinan dengan jarak yang sudah dihitung ulang
  DestinationInfo copyWithDistance(String dist, String detailDist) {
    return DestinationInfo(
      id: id,
      title: title,
      distance: dist,
      detailDistance: detailDist,
      icon: icon,
      color: color,
      lat: lat,
      lng: lng,
    );
  }
}
