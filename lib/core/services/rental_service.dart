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

    final data = await client
        .from('rental_profiles')
        .insert({
          'owner_id': user.id,
          'nama_rental': namaRental,
          'no_wa': noWa,
          'is_active': true,
        })
        .select('*, rental_settings(*)')
        .single();

    return RentalProfile.fromMap(data);
  }

  Future<RentalProfile> pastikanRentalSayaAda() async {
    final rental = await ambilRentalSaya();
    if (rental != null) return rental;
    return buatRentalDasarSaya();
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
