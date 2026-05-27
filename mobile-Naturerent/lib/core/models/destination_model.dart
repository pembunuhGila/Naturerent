class DestinationModel {
  final String id;
  final String name;
  final String location;
  final String? imageUrl;
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  const DestinationModel({
    required this.id,
    required this.name,
    required this.location,
    this.imageUrl,
    required this.description,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory DestinationModel.fromMap(Map<String, dynamic> map) {
    return DestinationModel(
      id: map['id'] as String,
      name: map['nama'] as String? ?? 'Destinasi',
      location: map['kategori'] as String? ?? 'Wisata',
      imageUrl: map['foto_url'] as String?,
      description: map['deskripsi'] as String? ?? '',
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class DestinationInput {
  final String name;
  final String location;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const DestinationInput({
    required this.name,
    required this.location,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toWisataPayload() {
    return {
      'nama': name,
      'kategori': location,
      'deskripsi': description,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'foto_url': imageUrl,
      'lat': latitude,
      'lng': longitude,
    };
  }
}
