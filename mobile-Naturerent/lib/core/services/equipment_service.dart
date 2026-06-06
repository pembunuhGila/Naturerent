import 'dart:typed_data';

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

  /// Ambil semua alat rental untuk dashboard pemilik, termasuk yang nonaktif.
  Future<List<Equipment>> ambilSemuaAlatByRental(String rentalId) async {
    final data = await client
        .from('equipment')
        .select('''
          *,
          equipment_categories(nama, icon),
          rental_profiles(nama_rental),
          equipment_images(image_url, is_primary, sort_order)
        ''')
        .eq('rental_id', rentalId)
        .order('nama');

    return (data as List)
        .map((e) => Equipment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Ambil alat per rental, difilter berdasarkan category_id.
  Future<List<Equipment>> ambilAlatByKategori(
    String rentalId,
    String categoryId,
  ) async {
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

  Future<void> tambahAlat({
    required String rentalId,
    required String nama,
    required String? categoryId,
    required String? deskripsi,
    required String? size,
    required double hargaPerHari,
    required int stock,
    String? imageUrl,
  }) async {
    await client.from('equipment').insert({
      'rental_id': rentalId,
      'category_id': categoryId,
      'nama': nama,
      'deskripsi': deskripsi,
      'size': size,
      'harga_per_hari': hargaPerHari,
      'stock': stock,
      'image_url': imageUrl,
      'is_available': true,
    });
  }

  Future<String> uploadFotoAlat({
    required Uint8List bytes,
    required String rentalId,
    String? equipmentId,
    String extension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ownerPath = equipmentId ?? 'new';
    final storagePath = '$rentalId/$ownerPath/$timestamp.$extension';

    await client.storage
        .from('equipment-images')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return client.storage.from('equipment-images').getPublicUrl(storagePath);
  }

  Future<void> perbaruiAlat({
    required String equipmentId,
    required String nama,
    required String? categoryId,
    required String? deskripsi,
    required String? size,
    required double hargaPerHari,
    required int stock,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'nama': nama,
      'category_id': categoryId,
      'deskripsi': deskripsi,
      'size': size,
      'harga_per_hari': hargaPerHari,
      'stock': stock,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }

    await client.from('equipment').update(data).eq('id', equipmentId);
  }

  Future<void> hapusAlat(String equipmentId) async {
    await client.from('equipment').delete().eq('id', equipmentId);
  }

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
    final result = await client.rpc(
      'check_availability',
      params: {
        'p_equipment_id': equipmentId,
        'p_start_date': tglMulai.toIso8601String().substring(0, 10),
        'p_end_date': tglSelesai.toIso8601String().substring(0, 10),
        'p_quantity': jumlah,
      },
    );
    return result as bool? ?? false;
  }
}
