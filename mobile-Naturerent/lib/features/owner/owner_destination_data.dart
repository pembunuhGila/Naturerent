import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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

// Destinasi yang sudah diverifikasi dekat dari rental (koordinat sekitar Semeru)
const ownerNearbyDestinations = [
  DestinationInfo(
    title: 'Ranu Kumbolo',
    distance: '2.2 km',
    detailDistance: '2.2 km dari rental',
    icon: Icons.water_rounded,
    color: AppColors.ownerPrimaryGreen,
    lat: -8.0559,
    lng: 112.9653,
  ),
  DestinationInfo(
    title: 'Gunung Semeru',
    distance: '2.4 km',
    detailDistance: '2.4 km dari rental',
    icon: Icons.terrain_rounded,
    color: Color(0xFF336A77),
    lat: -8.1084,
    lng: 112.9222,
  ),
  DestinationInfo(
    title: 'Alas Burno',
    distance: '1.8 km',
    detailDistance: '1.8 km dari rental',
    icon: Icons.forest_rounded,
    color: AppColors.ownerPrimaryGreen,
    lat: -8.0822,
    lng: 112.9374,
  ),
  DestinationInfo(
    title: 'Madakaripura',
    distance: '12 km',
    detailDistance: '12 km dari rental',
    icon: Icons.waterfall_chart_rounded,
    color: AppColors.ownerPrimaryGreen,
    lat: -7.8956,
    lng: 113.0284,
  ),
];

// Kandidat destinasi yang bisa ditambahkan oleh owner
const ownerCandidateDestinations = [
  DestinationInfo(
    title: 'Gunung Semeru',
    distance: '2.5 km',
    detailDistance: '2.5 km dari rental',
    icon: Icons.terrain_rounded,
    color: Color(0xFF336A77),
    lat: -8.1084,
    lng: 112.9222,
  ),
  DestinationInfo(
    title: 'Ranu Regulo',
    distance: '5.0 km',
    detailDistance: '5.0 km dari rental',
    icon: Icons.water_rounded,
    color: Color(0xFF385B57),
    lat: -8.0447,
    lng: 112.9681,
  ),
  DestinationInfo(
    title: 'Madakaripura',
    distance: '12 km',
    detailDistance: '12 km dari rental',
    icon: Icons.waterfall_chart_rounded,
    color: AppColors.ownerPrimaryGreen,
    lat: -7.8956,
    lng: 113.0284,
  ),
];
