import 'package:flutter_test/flutter_test.dart';
import 'package:naturerent/core/models/wisata_location.dart';
import 'package:naturerent/core/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('calculateDistanceKm returns a reasonable Haversine distance', () {
      final distance = LocationService.calculateDistanceKm(
        -8.0559,
        112.9653,
        -8.1084,
        112.9222,
      );

      expect(distance, greaterThan(7));
      expect(distance, lessThan(8));
    });

    test('getNearestWisata skips destinations without coordinates', () {
      final destinations = [
        WisataLocation(
          id: 'missing-coordinates',
          nama: 'Destinasi Belum Lengkap',
          createdAt: DateTime(2026),
        ),
        WisataLocation(
          id: 'near',
          nama: 'Destinasi Dekat',
          lat: -8.056,
          lng: 112.965,
          createdAt: DateTime(2026),
        ),
        WisataLocation(
          id: 'far',
          nama: 'Destinasi Jauh',
          lat: -7.8956,
          lng: 113.0284,
          createdAt: DateTime(2026),
        ),
      ];

      final nearest = LocationService.getNearestWisata(
        rentalLat: -8.0559,
        rentalLng: 112.9653,
        wisataList: destinations,
        maxResults: 5,
      );

      expect(nearest, hasLength(2));
      expect(nearest.first.wisata.id, 'near');
      expect(
        nearest.map((item) => item.wisata.id),
        isNot(contains('missing-coordinates')),
      );
    });
  });
}
