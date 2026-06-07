import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/equipment.dart';
import 'auth_service.dart';

class EquipmentService {
  static final EquipmentService _instance = EquipmentService._internal();
  factory EquipmentService() => _instance;
  EquipmentService._internal();

  static SupabaseClient get client => AuthService.client;
  static const String _newCategoryPrefix = '__new_category__:';
  static const List<String> _defaultCategoryNames = [
    'Peralatan Masak',
    'Lainnya',
    'Tenda',
    'Lampu & Senter',
    'Sleeping Bag',
    'Meja & Kursi',
    'Pakaian & Alas Kaki',
    'Peralatan Hiking',
    'P3K',
    'Matras',
    'Carrier / Tas',
  ];

  String? _categoryNameFromMap(Map<String, dynamic> data) {
    return data['nama'] as String? ??
        data['name'] as String? ??
        data['label'] as String? ??
        data['title'] as String?;
  }

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
    int? capacity,
    double? weightKg,
    required double hargaPerHari,
    required int stock,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'rental_id': rentalId,
      'category_id': categoryId,
      'nama': nama,
      'deskripsi': deskripsi,
      'harga_per_hari': hargaPerHari,
      'stock': stock,
      'image_url': imageUrl,
      'is_available': true,
    };

    if (size != null && size.isNotEmpty) {
      data['size'] = size;
    }
    if (capacity != null) {
      data['capacity'] = capacity;
    }
    if (weightKg != null) {
      data['weight_kg'] = weightKg;
    }

    await client.from('equipment').insert(data);
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
    int? capacity,
    double? weightKg,
    required double hargaPerHari,
    required int stock,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'nama': nama,
      'category_id': categoryId,
      'deskripsi': deskripsi,
      'harga_per_hari': hargaPerHari,
      'stock': stock,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (size != null && size.isNotEmpty) {
      data['size'] = size;
    } else {
      data['size'] = null;
    }
    data['capacity'] = capacity;
    data['weight_kg'] = weightKg;

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
    try {
      final data = await client
          .from('equipment_categories')
          .select('*');
      final rows = List<Map<String, dynamic>>.from(data as List);
      final categories = rows
          .map((row) {
            final id = row['id'] as String?;
            final name = _categoryNameFromMap(row);
            if (id == null || id.isEmpty || name == null || name.isEmpty) {
              return null;
            }
            return <String, dynamic>{
              ...row,
              'id': id,
              'nama': name,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      categories.sort((a, b) {
        final nameA = a['nama'] as String;
        final nameB = b['nama'] as String;
        // "Lainnya" selalu di paling bawah
        if (nameA.toLowerCase() == 'lainnya') return 1;
        if (nameB.toLowerCase() == 'lainnya') return -1;
        return nameA.compareTo(nameB);
      });
      if (categories.isNotEmpty) return categories;
    } catch (e) {
      debugPrint('Gagal memuat equipment_categories: $e');
      // Kalau RLS/policy kategori belum siap, tetap tampilkan opsi kategori
      // dasar agar pemilik rental bisa memilih kategori saat mengisi alat.
    }
    return kategoriBawaan();
  }

  List<Map<String, dynamic>> kategoriBawaan() {
    final list = _defaultCategoryNames
        .map(
          (name) => <String, dynamic>{
            'id': '$_newCategoryPrefix$name',
            'nama': name,
            'is_fallback': true,
          },
        )
        .toList();
    list.sort((a, b) {
      final nameA = a['nama'] as String;
      final nameB = b['nama'] as String;
      if (nameA.toLowerCase() == 'lainnya') return 1;
      if (nameB.toLowerCase() == 'lainnya') return -1;
      return nameA.compareTo(nameB);
    });
    return list;
  }

  Future<String?> pastikanCategoryId(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return null;
    if (!categoryId.startsWith(_newCategoryPrefix)) return categoryId;

    final categoryName = categoryId.substring(_newCategoryPrefix.length);
    if (categoryName.isEmpty) return null;

    final existing = await client
        .from('equipment_categories')
        .select('id')
        .eq('nama', categoryName)
        .maybeSingle();
    if (existing != null && existing['id'] != null) {
      return existing['id'] as String;
    }

    try {
      final inserted = await client
          .from('equipment_categories')
          .insert({
            'nama': categoryName,
            'icon': categoryName.toLowerCase().replaceAll(' ', '_'),
          })
          .select('id')
          .single();
      return inserted['id'] as String;
    } catch (_) {
      final retry = await client
          .from('equipment_categories')
          .select('id')
          .eq('nama', categoryName)
          .maybeSingle();
      if (retry != null && retry['id'] != null) return retry['id'] as String;

      throw Exception(
        'Kategori "$categoryName" belum bisa disimpan. '
        'Pastikan table equipment_categories punya policy SELECT dan INSERT untuk user login.',
      );
    }
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
