/// Model untuk tabel `wisata_locations`
class WisataLocation {
  final String id;
  final String nama;
  final String? deskripsi;
  final String? fotoUrl;
  final String? kategori; // 'Gunung', 'Ranu', 'Hutan', 'Pantai'
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  const WisataLocation({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.fotoUrl,
    this.kategori,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory WisataLocation.fromMap(Map<String, dynamic> map) {
    return WisataLocation(
      id: map['id'] as String,
      nama: map['nama'] as String,
      deskripsi: map['deskripsi'] as String?,
      fotoUrl: map['foto_url'] as String?,
      kategori: map['kategori'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
