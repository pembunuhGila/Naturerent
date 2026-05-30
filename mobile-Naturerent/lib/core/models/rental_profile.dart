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

  String? get openTime => _readOperationalTime(settings, [
    'open_time',
    'jam_buka',
    'buka',
    'open',
    'start',
    'from',
  ]);

  String? get closeTime => _readOperationalTime(settings, [
    'close_time',
    'jam_tutup',
    'tutup',
    'close',
    'end',
    'to',
  ]);

  String? get operationalHours {
    final open = openTime;
    final close = closeTime;
    if (open != null && close != null) return '$open - $close WIB';

    final raw = settings?['jam_operasional'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    if (raw is Map) {
      final text = _firstNonEmpty([
        raw['operational_hours']?.toString(),
        raw['jam_operasional']?.toString(),
        raw['label']?.toString(),
        raw['text']?.toString(),
      ]);
      if (text != null) return text;
    }

    return _firstNonEmpty([
      settings?['operational_hours']?.toString(),
      settings?['jam_operasional_text']?.toString(),
    ]);
  }

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

String? _readOperationalTime(
  Map<String, dynamic>? settings,
  List<String> keys,
) {
  if (settings == null) return null;

  for (final key in keys) {
    final value = settings[key];
    if (value == null) continue;
    final normalized = _normalizeTime(value.toString());
    if (normalized != null) return normalized;
  }

  final raw = settings['jam_operasional'];
  if (raw is Map) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final normalized = _normalizeTime(value.toString());
      if (normalized != null) return normalized;
    }
  } else if (raw is String) {
    final match = RegExp(
      r'(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})',
    ).firstMatch(raw);
    if (match != null) {
      final wantsClose = keys.any(
        (key) => key.contains('close') || key.contains('tutup') || key == 'to',
      );
      return _normalizeTime(match.group(wantsClose ? 2 : 1)!);
    }
  }

  return null;
}

String? _normalizeTime(String value) {
  final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(value);
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    return null;
  }
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
