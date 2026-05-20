import 'package:flutter/material.dart';

class DestinationInfo {
  final String title;
  final String distance;
  final String detailDistance;
  final IconData icon;
  final Color color;

  const DestinationInfo({
    required this.title,
    required this.distance,
    required this.detailDistance,
    required this.icon,
    required this.color,
  });
}

const ownerNearbyDestinations = [
  DestinationInfo(
    title: 'Ranu Kumbolo',
    distance: '2.2 km',
    detailDistance: '2.2 km dari rental',
    icon: Icons.water_rounded,
    color: Color(0xFF6B8E7D),
  ),
  DestinationInfo(
    title: 'Gunung Semeru',
    distance: '2.4 km',
    detailDistance: '2.4 km dari rental',
    icon: Icons.terrain_rounded,
    color: Color(0xFF336A77),
  ),
  DestinationInfo(
    title: 'Alas Burno',
    distance: '1.8 km',
    detailDistance: '1.8 km dari rental',
    icon: Icons.forest_rounded,
    color: Color(0xFF4E6A35),
  ),
  DestinationInfo(
    title: 'Madakaripura',
    distance: '12 km',
    detailDistance: '12 km dari rental',
    icon: Icons.waterfall_chart_rounded,
    color: Color(0xFF6F9A3D),
  ),
];

const ownerCandidateDestinations = [
  DestinationInfo(
    title: 'Gunung Semeru',
    distance: '2.5 km',
    detailDistance: '2.5 km dari rental',
    icon: Icons.terrain_rounded,
    color: Color(0xFF6A8FA1),
  ),
  DestinationInfo(
    title: 'Ranu Regulo',
    distance: '5.0 km',
    detailDistance: '5.0 km dari rental',
    icon: Icons.water_rounded,
    color: Color(0xFF385B57),
  ),
  DestinationInfo(
    title: 'Madakaripura',
    distance: '12 km',
    detailDistance: '12 km dari rental',
    icon: Icons.waterfall_chart_rounded,
    color: Color(0xFF6F9A3D),
  ),
];
