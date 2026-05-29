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
  final String?
  fotoBanner; // URL dari Supabase Storage — null berarti belum ada foto
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // QRIS per-rental (diatur admin di System Settings > QRIS Configuration)
  final String? qrisImageUrl; // URL gambar QRIS milik rental ini
  final String? qrisMerchantName; // Nama merchant QRIS rental ini

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
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.qrisImageUrl,
    this.qrisMerchantName,
    this.settings,
  });

  factory RentalProfile.fromMap(Map<String, dynamic> map) {
    final owner = map['users'] is Map<String, dynamic>
        ? map['users'] as Map<String, dynamic>
        : null;
    final settingsData = map['rental_settings'];
    Map<String, dynamic>? settings;
    if (settingsData is Map<String, dynamic>) {
      settings = settingsData;
    } else if (settingsData is List &&
        settingsData.isNotEmpty &&
        settingsData.first is Map<String, dynamic>) {
      settings = settingsData.first as Map<String, dynamic>;
    }

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
      ownerName: owner?['nama_lengkap'] as String?,
      ownerEmail: owner?['email'] as String?,
      ownerPhone: owner?['no_wa'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      qrisImageUrl: map['qris_image_url'] as String?,
      qrisMerchantName: map['qris_merchant_name'] as String?,
      settings: settings,
    );
  }
}
