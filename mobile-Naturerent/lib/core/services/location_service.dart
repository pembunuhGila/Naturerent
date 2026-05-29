import 'package:geolocator/geolocator.dart';
import '../models/rental_profile.dart';
import '../models/wisata_location.dart';

/// Helper service untuk kalkulasi jarak geografis dan pencarian destinasi terdekat.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Hitung jarak antara dua titik koordinat.
  /// Mengembalikan jarak dalam kilometer.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Format jarak ke string yang readable.
  /// Contoh: 0.8 → "800 m", 2.5 → "2.5 km"
  static String formatJarak(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static double? distanceToRentalKm({
    required double referenceLat,
    required double referenceLng,
    required RentalProfile rental,
  }) {
    if (rental.lat == null || rental.lng == null) return null;

    return calculateDistanceKm(
      referenceLat,
      referenceLng,
      rental.lat!,
      rental.lng!,
    );
  }

  /// Urutkan rental dari titik referensi. Rental tanpa koordinat ditaruh bawah.
  static List<RentalWithDistance> sortRentalsByDistance({
    required double referenceLat,
    required double referenceLng,
    required List<RentalProfile> rentals,
    bool includeUnknownLocation = true,
  }) {
    final result = rentals
        .where(
          (r) => includeUnknownLocation || (r.lat != null && r.lng != null),
        )
        .map(
          (r) => RentalWithDistance(
            rental: r,
            distanceKm: distanceToRentalKm(
              referenceLat: referenceLat,
              referenceLng: referenceLng,
              rental: r,
            ),
          ),
        )
        .toList();

    result.sort((a, b) {
      final da = a.distanceKm;
      final db = b.distanceKm;
      if (da == null && db == null) {
        return a.rental.namaRental.compareTo(b.rental.namaRental);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return result;
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

/// Model hasil perhitungan jarak rental dari titik referensi.
class RentalWithDistance {
  final RentalProfile rental;
  final double? distanceKm;

  const RentalWithDistance({required this.rental, required this.distanceKm});

  String get jarakFormatted {
    final distance = distanceKm;
    if (distance == null) return 'Lokasi belum tersedia';
    return LocationService.formatJarak(distance);
  }
}

/// Model hasil perhitungan jarak wisata dari titik referensi.
class WisataWithDistance {
  final WisataLocation wisata;
  final double distanceKm;

  const WisataWithDistance({required this.wisata, required this.distanceKm});

  /// Jarak sudah diformat dalam string (m / km).
  String get jarakFormatted => LocationService.formatJarak(distanceKm);
}
