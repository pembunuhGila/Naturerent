import '../models/rental_profile.dart';
import 'location_service.dart';
import 'rental_service.dart';

/// Service untuk membuat saran destinasi terdekat dari titik toko rental.
///
/// Implementasi awal memakai data destinasi internal dari tabel
/// `wisata_locations`, lalu menghitung jarak dengan Haversine.
class DestinationSuggestionService {
  final RentalService _rentalService;

  DestinationSuggestionService({RentalService? rentalService})
      : _rentalService = rentalService ?? RentalService();

  /// Ambil destinasi terdekat dari koordinat toko rental.
  ///
  /// Destinasi tanpa latitude/longitude dilewati oleh [LocationService],
  /// sehingga data yang belum lengkap tidak menyebabkan error.
  Future<List<WisataWithDistance>> ambilSaranDestinasiTerdekat({
    required double? rentalLat,
    required double? rentalLng,
    int limit = 5,
  }) async {
    if (rentalLat == null || rentalLng == null) return [];

    final wisataList = await _rentalService.ambilSemuaWisata();
    return LocationService.getNearestWisata(
      rentalLat: rentalLat,
      rentalLng: rentalLng,
      wisataList: wisataList,
      maxResults: limit,
    );
  }

  /// Convenience helper untuk profil rental yang sudah dimuat.
  Future<List<WisataWithDistance>> ambilSaranUntukRental(
    RentalProfile? rental, {
    int limit = 5,
  }) {
    return ambilSaranDestinasiTerdekat(
      rentalLat: rental?.lat,
      rentalLng: rental?.lng,
      limit: limit,
    );
  }
}
