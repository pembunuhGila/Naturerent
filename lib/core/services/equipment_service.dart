import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import 'auth_service.dart';

class EquipmentService {
  static final EquipmentService _instance = EquipmentService._internal();
  factory EquipmentService() => _instance;
  EquipmentService._internal();

  static SupabaseClient get client => AuthService.client;

  // ──────────────────────────────────────────────────────────
  //  AMBIL ALAT PER RENTAL
  // ──────────────────────────────────────────────────────────

  /// Ambil semua alat yang tersedia dari satu rental, beserta kategori & foto.
  Future<List<Equipment>> ambilAlatByRental(String rentalId) async {
    final data = await client
        .from('equipment')
        .select('''
          *,
          equipment_categories(nama, icon),
          rental_profiles(nama_rental),
          equipment_images(image_url, is_primary, sort_order)
        ''')
        .eq('rental_id', rentalId)
        .eq('is_available', true)
        .order('nama');

    return (data as List)
        .map((e) => Equipment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil alat per rental, difilter berdasarkan category_id.
  Future<List<Equipment>> ambilAlatByKategori(
      String rentalId, String categoryId) async {
    final data = await client
        .from('equipment')
        .select('''
          *,
          equipment_categories(nama, icon),
          rental_profiles(nama_rental),
          equipment_images(image_url, is_primary, sort_order)
        ''')
        .eq('rental_id', rentalId)
        .eq('category_id', categoryId)
        .eq('is_available', true)
        .order('nama');

    return (data as List)
        .map((e) => Equipment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────────────────────
  //  DETAIL SATU ALAT
  // ──────────────────────────────────────────────────────────

  /// Ambil detail lengkap satu alat beserta semua fotonya.
  Future<Equipment?> ambilDetailAlat(String equipmentId) async {
    final data = await client
        .from('equipment')
        .select('''
          *,
          equipment_categories(nama, icon),
          rental_profiles(nama_rental, alamat, no_wa),
          equipment_images(image_url, is_primary, sort_order)
        ''')
        .eq('id', equipmentId)
        .maybeSingle();

    if (data == null) return null;
    return Equipment.fromMap(data);
  }

  // ──────────────────────────────────────────────────────────
  //  KATEGORI
  // ──────────────────────────────────────────────────────────

  /// Ambil semua kategori alat (untuk filter chip).
  Future<List<Map<String, dynamic>>> ambilKategori() async {
    final data = await client
        .from('equipment_categories')
        .select('id, nama, icon')
        .order('nama');
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ──────────────────────────────────────────────────────────
  //  CEK KETERSEDIAAN
  // ──────────────────────────────────────────────────────────

  /// Cek stok tersedia untuk rentang tanggal tertentu via Supabase function.
  Future<bool> cekKetersediaan({
    required String equipmentId,
    required DateTime tglMulai,
    required DateTime tglSelesai,
    required int jumlah,
  }) async {
    final result = await client.rpc('check_availability', params: {
      'p_equipment_id': equipmentId,
      'p_start_date': tglMulai.toIso8601String().substring(0, 10),
      'p_end_date': tglSelesai.toIso8601String().substring(0, 10),
      'p_quantity': jumlah,
    });
    return result as bool? ?? false;
  }
}
