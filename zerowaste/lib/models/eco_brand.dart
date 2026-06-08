class EcoBrand {
  const EcoBrand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.verified,
  });

  final String id;
  final String name;
  final String tagline;
  final bool verified;

  factory EcoBrand.fromMap(Map<String, dynamic> map) {
    return EcoBrand(
      id: map['id'] as String,
      name: map['name'] as String,
      tagline: map['tagline'] as String? ?? '',
      verified: map['verified'] as bool? ?? false,
    );
  }
}
