/// Model untuk tabel `equipment` beserta join ke kategori dan rental
class Equipment {
  final String id;
  final String rentalId;
  final String? categoryId;
  final String nama;
  final String? deskripsi;
  final String? size;
  final int? capacity;
  final double? weightKg;
  final double hargaPerHari;
  final int stock;
  final String? imageUrl; // kolom image_url di tabel equipment
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Dari join
  final String? namaKategori;
  final String? ikonKategori;
  final String? namaRental;
  final List<String> extraImages; // dari equipment_images

  const Equipment({
    required this.id,
    required this.rentalId,
    this.categoryId,
    required this.nama,
    this.deskripsi,
    this.size,
    this.capacity,
    this.weightKg,
    required this.hargaPerHari,
    required this.stock,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.namaKategori,
    this.ikonKategori,
    this.namaRental,
    this.extraImages = const [],
  });

  factory Equipment.fromMap(Map<String, dynamic> map) {
    // Join equipment_categories
    final cat = map['equipment_categories'] as Map<String, dynamic>?;
    // Join rental_profiles
    final rental = map['rental_profiles'] as Map<String, dynamic>?;
    // Join equipment_images (list)
    final imgs =
        (map['equipment_images'] as List?)
            ?.map((e) => e['image_url'] as String)
            .toList() ??
        [];
    final sizeRows =
        (map['equipment_sizes'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    String? sizeValue = map['size'] as String?;
    if (sizeRows.isNotEmpty) {
      final pairs = sizeRows
          .map((row) {
            final size = (row['size'] as String? ?? '').trim().replaceAll(
              '"',
              r'\"',
            );
            final stock = (row['stock'] as num?)?.toInt() ?? 0;
            return '"$size":$stock';
          })
          .where((pair) => !pair.startsWith('"":'));
      sizeValue = '{${pairs.join(',')}}';
    }

    return Equipment(
      id: map['id'] as String,
      rentalId: map['rental_id'] as String,
      categoryId: map['category_id'] as String?,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
      size: sizeValue,
      capacity: (map['capacity'] as num?)?.toInt(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      hargaPerHari: (map['harga_per_hari'] as num).toDouble(),
      stock: map['stock'] as int,
      imageUrl: map['image_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      namaKategori: cat?['nama'] as String?,
      ikonKategori: cat?['icon'] as String?,
      namaRental: rental?['nama_rental'] as String?,
      extraImages: imgs,
    );
  }

  /// Semua URL gambar: utama + extra dari equipment_images
  List<String> get semuaGambar {
    final all = <String>[];
    if (imageUrl != null && imageUrl!.isNotEmpty) all.add(imageUrl!);
    for (final img in extraImages) {
      if (!all.contains(img)) all.add(img);
    }
    return all;
  }

  /// Gambar pertama (untuk thumbnail)
  String? get gambarprimaryUrl =>
      semuaGambar.isNotEmpty ? semuaGambar.first : null;

  /// Parse size field sebagai map {size: stock}.
  /// Format baru: JSON `{"S":5,"M":10,"L":3}`
  /// Format lama: plain string "S, M, L" → semua size = stock equipment
  Map<String, int> get sizeStockMap {
    if (size == null || size!.trim().isEmpty) return {};
    final trimmed = size!.trim();

    // Coba parse sebagai JSON map
    if (trimmed.startsWith('{')) {
      try {
        final decoded = _jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        }
      } catch (_) {}
    }

    // Fallback: plain string "S, M, L" → tiap size = stock penuh
    final parts = trimmed
        .split(RegExp(r'[,;/]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    if (parts.isEmpty) return {};
    return {for (final s in parts) s: stock};
  }

  /// Daftar semua size yang tersedia (stock > 0)
  List<String> get availableSizes =>
      sizeStockMap.entries.where((e) => e.value > 0).map((e) => e.key).toList();

  /// Semua size (termasuk yang habis)
  List<String> get allSizes => sizeStockMap.keys.toList();

  static dynamic _jsonDecode(String source) {
    // Minimal JSON map parser to avoid importing dart:convert everywhere
    // ignore: avoid_dynamic_calls
    return _SimpleJsonParser.parse(source);
  }
}

/// Minimal JSON map parser for size-stock field
class _SimpleJsonParser {
  static dynamic parse(String source) {
    final s = source.trim();
    if (!s.startsWith('{') || !s.endsWith('}')) return null;
    final inner = s.substring(1, s.length - 1).trim();
    if (inner.isEmpty) return <String, dynamic>{};
    final map = <String, dynamic>{};
    // Split by comma, but respect quoted strings
    for (final pair in _splitPairs(inner)) {
      final colonIdx = pair.indexOf(':');
      if (colonIdx < 0) continue;
      var key = pair.substring(0, colonIdx).trim();
      final valStr = pair.substring(colonIdx + 1).trim();
      // Remove quotes from key
      if (key.startsWith('"') && key.endsWith('"')) {
        key = key.substring(1, key.length - 1);
      }
      final num? val = int.tryParse(valStr) ?? double.tryParse(valStr);
      if (val != null) map[key] = val;
    }
    return map;
  }

  static List<String> _splitPairs(String s) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    var inQuote = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '"') inQuote = !inQuote;
      if (!inQuote) {
        if (c == '{' || c == '[') depth++;
        if (c == '}' || c == ']') depth--;
        if (c == ',' && depth == 0) {
          result.add(s.substring(start, i));
          start = i + 1;
        }
      }
    }
    if (start < s.length) result.add(s.substring(start));
    return result;
  }
}
