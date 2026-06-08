import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wisata_location.dart';
import '../models/rental_profile.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// Service untuk mengambil data wisata dan rental dari Supabase.
class RentalService {
  static final RentalService _instance = RentalService._internal();
  factory RentalService() => _instance;
  RentalService._internal();

  static SupabaseClient get client => AuthService.client;
  static const String rentalSelect =
      '*, users!owner_id(nama_lengkap, email, no_wa), rental_settings(*)';

  // ──────────────────────────────────────────────────────────
  //  WISATA LOCATIONS
  // ──────────────────────────────────────────────────────────

  /// Ambil semua lokasi wisata, diurutkan dari yang terbaru.
  Future<List<WisataLocation>> ambilSemuaWisata() async {
    final data = await client
        .from('wisata_locations')
        .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
        .neq('kategori', 'QRIS')
        .order('kategori')
        .order('nama');

    return (data as List)
        .map((e) => WisataLocation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil destinasi wisata yang dipilih pemilik untuk rental tertentu.
  Future<List<WisataLocation>> ambilWisataRental(String rentalId) async {
    final data = await client
        .from('rental_wisata')
        .select(
          'wisata_locations(id, nama, deskripsi, foto_url, kategori, lat, lng, created_at)',
        )
        .eq('rental_id', rentalId);

    return (data as List)
        .map((e) => e['wisata_locations'])
        .whereType<Map<String, dynamic>>()
        .map(WisataLocation.fromMap)
        .toList();
  }

  /// Simpan ulang daftar destinasi pilihan pemilik rental.
  Future<void> simpanWisataRental({
    required String rentalId,
    required List<String> wisataIds,
  }) async {
    await client.from('rental_wisata').delete().eq('rental_id', rentalId);

    final uniqueIds = wisataIds.toSet().toList();
    if (uniqueIds.isEmpty) return;

    await client.from('rental_wisata').insert(
          uniqueIds
              .map(
                (wisataId) => {
                  'rental_id': rentalId,
                  'wisata_id': wisataId,
                },
              )
              .toList(),
        );
  }

  // ──────────────────────────────────────────────────────────
  //  RENTAL PROFILES
  // ──────────────────────────────────────────────────────────

  /// Ambil semua rental yang aktif beserta settings-nya.
  Future<List<RentalProfile>> ambilRentalAktif() async {
    final data = await client
        .from('rental_profiles')
        .select(rentalSelect)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => RentalProfile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Hitung total stok alat yang tersedia untuk setiap rental.
  Future<Map<String, int>> ambilJumlahAlatTersedia(
    List<String> rentalIds,
  ) async {
    if (rentalIds.isEmpty) return {};

    final data = await client
        .from('equipment')
        .select('rental_id, stock, is_available')
        .inFilter('rental_id', rentalIds)
        .eq('is_available', true);

    final counts = <String, int>{};
    for (final row in (data as List).whereType<Map<String, dynamic>>()) {
      final rentalId = row['rental_id'] as String?;
      final stock = (row['stock'] as num?)?.toInt() ?? 0;
      if (rentalId == null || stock <= 0) continue;
      counts[rentalId] = (counts[rentalId] ?? 0) + stock;
    }

    return counts;
  }

  /// Ambil profil rental milik user owner yang sedang login.
  Future<RentalProfile?> ambilRentalSaya() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return null;

    final data = await client
        .from('rental_profiles')
        .select(rentalSelect)
        .eq('owner_id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return RentalProfile.fromMap(data);
  }

  Future<RentalProfile> buatRentalDasarSaya() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) throw Exception('Belum masuk.');

    final meta = user.userMetadata ?? {};
    final namaRental =
        (meta['store_name'] as String?) ??
        (meta['full_name'] as String?) ??
        user.email?.split('@').first ??
        'Rental Baru';
    final noWa = meta['no_wa'] as String?;
    final alamat = meta['store_address'] as String?;

    final payload = <String, dynamic>{
      'owner_id': user.id,
      'nama_rental': namaRental,
      'is_active': true,
    };
    if (noWa != null && noWa.isNotEmpty) payload['no_wa'] = noWa;
    if (alamat != null && alamat.isNotEmpty) payload['alamat'] = alamat;

    final data = await client
        .from('rental_profiles')
        .insert(payload)
        .select(rentalSelect)
        .single();

    return RentalProfile.fromMap(data);
  }

  Future<RentalProfile> pastikanRentalSayaAda() async {
    final rental = await ambilRentalSaya();
    if (rental != null) return _lengkapiRentalDariMetadata(rental);
    return buatRentalDasarSaya();
  }

  Future<RentalProfile> _lengkapiRentalDariMetadata(
    RentalProfile rental,
  ) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return rental;

    final meta = user.userMetadata ?? {};
    final storeName = meta['store_name'] as String?;
    final alamat = meta['store_address'] as String?;
    final noWa = meta['no_wa'] as String?;
    final fallbackName = user.email?.split('@').first;

    final payload = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (storeName != null &&
        storeName.isNotEmpty &&
        (rental.namaRental == 'Rental Baru' ||
            rental.namaRental == fallbackName)) {
      payload['nama_rental'] = storeName;
    }
    if (alamat != null &&
        alamat.isNotEmpty &&
        (rental.alamat == null || rental.alamat!.isEmpty)) {
      payload['alamat'] = alamat;
    }
    if (noWa != null &&
        noWa.isNotEmpty &&
        (rental.noWa == null || rental.noWa!.isEmpty)) {
      payload['no_wa'] = noWa;
    }

    if (payload.length == 1) return rental;

    final data = await client
        .from('rental_profiles')
        .update(payload)
        .eq('id', rental.id)
        .eq('owner_id', user.id)
        .select(rentalSelect)
        .single();

    return RentalProfile.fromMap(data);
  }

  /// Update detail rental milik owner yang sedang login (nama, alamat, lat, lng).
  Future<RentalProfile> perbaruiDetailRental({
    required String rentalId,
    required String namaRental,
    String? alamat,
    double? lat,
    double? lng,
    String? openTime,
    String? closeTime,
  }) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) throw Exception('Belum masuk.');

    final payload = <String, dynamic>{
      'nama_rental': namaRental,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (alamat != null) payload['alamat'] = alamat;
    if (lat != null) payload['lat'] = lat;
    if (lng != null) payload['lng'] = lng;

    final data = await client
        .from('rental_profiles')
        .update(payload)
        .eq('id', rentalId)
        .eq('owner_id', user.id)
        .select(rentalSelect)
        .single();

    if (openTime != null && closeTime != null) {
      await _simpanJamOperasional(
        rentalId: rentalId,
        openTime: openTime,
        closeTime: closeTime,
      );

      final refreshed = await client
          .from('rental_profiles')
          .select(rentalSelect)
          .eq('id', rentalId)
          .eq('owner_id', user.id)
          .single();
      return RentalProfile.fromMap(refreshed);
    }

    return RentalProfile.fromMap(data);
  }

  Future<void> _simpanJamOperasional({
    required String rentalId,
    required String openTime,
    required String closeTime,
  }) async {
    final label = '$openTime - $closeTime WIB';
    final now = DateTime.now().toIso8601String();
    final structuredPayload = <String, dynamic>{
      'rental_id': rentalId,
      'jam_operasional': {
        'jam_buka': openTime,
        'jam_tutup': closeTime,
        'open_time': openTime,
        'close_time': closeTime,
        'operational_hours': label,
      },
      'updated_at': now,
    };

    try {
      await _tulisRentalSettings(rentalId, structuredPayload);
    } catch (_) {
      await _tulisRentalSettings(rentalId, {
        'rental_id': rentalId,
        'jam_operasional': label,
        'updated_at': now,
      });
    }
  }

  Future<void> _tulisRentalSettings(
    String rentalId,
    Map<String, dynamic> payload,
  ) async {
    final existing = await client
        .from('rental_settings')
        .select('rental_id')
        .eq('rental_id', rentalId)
        .limit(1);

    if (existing.isNotEmpty) {
      await client
          .from('rental_settings')
          .update(payload)
          .eq('rental_id', rentalId);
      return;
    }

    await client.from('rental_settings').insert(payload);
  }

  /// Konfirmasi pesanan yang telah disetujui admin, dilakukan oleh pemilik rental.
  Future<void> konfirmasiPesananPemilik(String bookingId) async {
    await client
        .from('bookings')
        .update({
          'status': 'processing',
          'confirmed_by_owner_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'confirmed');
  }

  /// Konfirmasi bahwa peralatan telah diambil oleh penyewa.
  Future<void> konfirmasiPengambilanPesananPemilik(String bookingId) async {
    await client
        .from('bookings')
        .update({
          'status': 'rented',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'processing');
  }

  /// Konfirmasi bahwa pesanan telah dikembalikan oleh penyewa.
  Future<void> konfirmasiPengembalianPesananPemilik(String bookingId) async {
    await client
        .from('bookings')
        .update({
          'status': 'returned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'rented');
  }

  /// Tandai pesanan telah selesai diproses oleh pemilik (siap diambil atau dikirim),
  /// dan kirim notifikasi ke penyewa.
  Future<void> tandaiPesananSiap(String bookingId) async {
    // Update processed_at agar tercatat kapan pemilik menyelesaikan persiapan.
    final updated = await client
        .from('bookings')
        .update({
          'processed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId)
        .eq('status', 'processing')
        .select('customer_id, booking_code')
        .maybeSingle();

    if (updated == null) return;

    final customerId = updated['customer_id'] as String?;
    final bookingCode = updated['booking_code'] as String?;

    if (customerId != null && customerId.isNotEmpty) {
      try {
        await client.from('notifications').insert({
          'user_id': customerId,
          'judul': 'Pesanan #${bookingCode ?? bookingId} siap',
          'pesan':
              'Pesanan Anda telah selesai diproses dan siap diambil atau dikirim.',
          'type': 'booking',
          'ref_id': bookingId,
        });
      } catch (_) {
        // Notifikasi bukan blocker
      }
    }
  }

  /// Ambil rental aktif yang diurutkan dari yang paling dekat ke wisata.
  Future<List<RentalProfile>> ambilRentalDekatWisata(String wisataId) async {
    final wisata = await client
        .from('wisata_locations')
        .select('lat, lng')
        .eq('id', wisataId)
        .maybeSingle();

    final wisataLat = (wisata?['lat'] as num?)?.toDouble();
    final wisataLng = (wisata?['lng'] as num?)?.toDouble();
    if (wisataLat == null || wisataLng == null) return [];

    final data = await client
        .from('rental_profiles')
        .select(rentalSelect)
        .eq('is_active', true);

    final rentals = (data as List)
        .map((e) => RentalProfile.fromMap(e as Map<String, dynamic>))
        .toList();

    return LocationService.sortRentalsByDistance(
      referenceLat: wisataLat,
      referenceLng: wisataLng,
      rentals: rentals,
      includeUnknownLocation: false,
    ).map((r) => r.rental).toList();
  }

  /// Cek apakah rental sudah di-favorit oleh user saat ini.
  Future<bool> cekFavorit(String rentalId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return false;

    final data = await client
        .from('rental_favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('rental_id', rentalId)
        .maybeSingle();

    return data != null;
  }

  /// Tambah rental ke favorit.
  Future<void> tambahFavorit(String rentalId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return;

    await client.from('rental_favorites').insert({
      'user_id': user.id,
      'rental_id': rentalId,
    });
  }

  /// Hapus rental dari favorit.
  Future<void> hapusFavorit(String rentalId) async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return;

    await client
        .from('rental_favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('rental_id', rentalId);
  }

  /// Ambil daftar favorit rental milik user saat ini.
  Future<List<RentalProfile>> ambilFavoritKu() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return [];

    final data = await client
        .from('rental_favorites')
        .select('rental_profiles($rentalSelect)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) {
          final rental = e['rental_profiles'] as Map<String, dynamic>;
          return RentalProfile.fromMap(rental);
        })
        .where((r) => r.isActive)
        .toList();
  }
}
