/// Model untuk tabel `equipment` beserta join ke kategori dan rental
class Equipment {
  final String id;
  final String rentalId;
  final String? categoryId;
  final String nama;
  final String? deskripsi;
  final String? size;
  final double hargaPerHari;
  final int stock;
  final String? imageUrl;   // kolom image_url di tabel equipment
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
    final imgs = (map['equipment_images'] as List?)
        ?.map((e) => e['image_url'] as String)
        .toList() ?? [];

    return Equipment(
      id: map['id'] as String,
      rentalId: map['rental_id'] as String,
      categoryId: map['category_id'] as String?,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
      size: map['size'] as String?,
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
  String? get gambarprimaryUrl => semuaGambar.isNotEmpty ? semuaGambar.first : null;
}
