class EcoBrand {
  const EcoBrand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.logoUrl,
    required this.verified,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String logoUrl;
  final bool verified;

  factory EcoBrand.fromMap(Map<String, dynamic> map) {
    return EcoBrand(
      id: map['id'] as String,
      name: map['name'] as String,
      tagline: map['tagline'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logo_url'] as String? ?? '',
      verified: map['verified'] as bool? ?? false,
    );
  }
}
