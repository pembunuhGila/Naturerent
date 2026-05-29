import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wisata_location.dart';
import '../models/rental_profile.dart';
import 'auth_service.dart';

/// Service untuk mengambil data wisata dan rental dari Supabase.
class RentalService {
  static final RentalService _instance = RentalService._internal();
  factory RentalService() => _instance;
  RentalService._internal();

  static SupabaseClient get client => AuthService.client;

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

  // ──────────────────────────────────────────────────────────
  //  RENTAL PROFILES
  // ──────────────────────────────────────────────────────────

  /// Ambil semua rental yang aktif beserta settings-nya.
  Future<List<RentalProfile>> ambilRentalAktif() async {
    final data = await client
        .from('rental_profiles')
        .select('*, rental_settings(*)')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => RentalProfile.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil profil rental milik user owner yang sedang login.
  Future<RentalProfile?> ambilRentalSaya() async {
    final user = AuthService().penggunaSaatIni;
    if (user == null) return null;

    final data = await client
        .from('rental_profiles')
        .select('*, rental_settings(*)')
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
        .select('*, rental_settings(*)')
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
        .select('*, rental_settings(*)')
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
        .select('*, rental_settings(*)')
        .single();

    return RentalProfile.fromMap(data);
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

    final customerId = (updated as Map<String, dynamic>)['customer_id'] as String?;
    final bookingCode = (updated as Map<String, dynamic>)['booking_code'] as String?;

    if (customerId != null && customerId.isNotEmpty) {
      try {
        await client.from('notifications').insert({
          'user_id': customerId,
          'judul': 'Pesanan #${bookingCode ?? bookingId} siap',
          'pesan': 'Pesanan Anda telah selesai diproses dan siap diambil atau dikirim.',
          'type': 'booking',
          'ref_id': bookingId,
        });
      } catch (_) {
        // Notifikasi bukan blocker
      }
    }
  }

  /// Ambil rental yang dekat dengan lokasi wisata tertentu.
  Future<List<RentalProfile>> ambilRentalDekatWisata(String wisataId) async {
    // Ambil rental yang terhubung ke wisata ini via rental_wisata
    final data = await client
        .from('rental_wisata')
        .select('rental_profiles(*, rental_settings(*))')
        .eq('wisata_id', wisataId);

    return (data as List)
        .map((e) {
          final rental = e['rental_profiles'] as Map<String, dynamic>;
          return RentalProfile.fromMap(rental);
        })
        .where((r) => r.isActive)
        .toList();
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
        .select('rental_profiles(*, rental_settings(*))')
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
