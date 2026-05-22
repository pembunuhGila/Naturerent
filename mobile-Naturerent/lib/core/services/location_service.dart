import 'dart:math' as math;
import '../models/wisata_location.dart';

/// Helper service untuk kalkulasi jarak geografis dan pencarian destinasi terdekat.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Hitung jarak antara dua titik koordinat menggunakan rumus Haversine.
  /// Mengembalikan jarak dalam kilometer.
  ///
  /// Contoh: calculateDistanceKm(-8.05, 112.96, -8.10, 113.00)
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Format jarak ke string yang readable.
  /// Contoh: 0.8 → "800 m", 2.5 → "2.5 km"
  static String formatJarak(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10.0) {
      // Satu desimal
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  /// Ambil N destinasi wisata terdekat dari titik koordinat rental.
  /// Destinasi yang tidak memiliki lat/lng akan dilewati (tidak error).
  ///
  /// [rentalLat] & [rentalLng] — koordinat toko rental.
  /// [wisataList] — daftar semua destinasi wisata.
  /// [maxResults] — jumlah maksimal hasil (default 5).
  static List<WisataWithDistance> getNearestWisata({
    required double rentalLat,
    required double rentalLng,
    required List<WisataLocation> wisataList,
    int maxResults = 5,
  }) {
    final withDistance = <WisataWithDistance>[];

    for (final wisata in wisataList) {
      // Lewati destinasi yang tidak punya koordinat
      if (wisata.lat == null || wisata.lng == null) continue;

      final distKm = calculateDistanceKm(
        rentalLat,
        rentalLng,
        wisata.lat!,
        wisata.lng!,
      );

      withDistance.add(WisataWithDistance(wisata: wisata, distanceKm: distKm));
    }

    // Urutkan berdasarkan jarak terdekat
    withDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return withDistance.take(maxResults).toList();
  }
}

/// Model hasil perhitungan jarak — pasangan wisata + jarak km.
class WisataWithDistance {
  final WisataLocation wisata;
  final double distanceKm;

  const WisataWithDistance({
    required this.wisata,
    required this.distanceKm,
  });

  /// Jarak sudah diformat dalam string (m / km).
  String get jarakFormatted => LocationService.formatJarak(distanceKm);
}
