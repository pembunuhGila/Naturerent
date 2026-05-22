/// Model untuk tabel `rental_profiles`
class RentalProfile {
  final String id;
  final String ownerId;
  final String namaRental;
  final String? deskripsi;
  final String? alamat;
  final double? lat;
  final double? lng;
  final String? noWa;
  final String? fotoProfil;
  final String? fotoBanner; // URL dari Supabase Storage — null berarti belum ada foto
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Opsional: dari join ke rental_settings
  final Map<String, dynamic>? settings;

  const RentalProfile({
    required this.id,
    required this.ownerId,
    required this.namaRental,
    this.deskripsi,
    this.alamat,
    this.lat,
    this.lng,
    this.noWa,
    this.fotoProfil,
    this.fotoBanner,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory RentalProfile.fromMap(Map<String, dynamic> map) {
    return RentalProfile(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      namaRental: map['nama_rental'] as String,
      deskripsi: map['deskripsi'] as String?,
      alamat: map['alamat'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      noWa: map['no_wa'] as String?,
      fotoProfil: map['foto_profil'] as String?,
      fotoBanner: map['foto_banner'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      settings: map['rental_settings'] as Map<String, dynamic>?,
    );
  }
}
