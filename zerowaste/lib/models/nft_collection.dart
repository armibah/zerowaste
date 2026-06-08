class NftCollection {
  const NftCollection({
    required this.id,
    required this.name,
    required this.creator,
    required this.description,
    required this.category,
    required this.floorPriceEth,
    required this.volumeEth,
    required this.items,
    required this.verified,
    required this.accentColor,
  });

  final String id;
  final String name;
  final String creator;
  final String description;
  final String category;
  final double floorPriceEth;
  final double volumeEth;
  final int items;
  final bool verified;
  final int accentColor;

  factory NftCollection.fromMap(Map<String, dynamic> map) {
    return NftCollection(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Untitled collection',
      creator: map['creator'] as String? ?? 'Unknown creator',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Art',
      floorPriceEth: _toDouble(map['floor_price_eth']),
      volumeEth: _toDouble(map['volume_eth']),
      items: (map['items'] as num?)?.round() ?? 0,
      verified: map['verified'] as bool? ?? false,
      accentColor: _parseColor(map['accent_color'], fallback: 0xFF8B5CF6),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _parseColor(dynamic value, {required int fallback}) {
  if (value is int) return value;
  final text = '$value'.replaceAll('#', '').replaceAll('0x', '');
  if (text.length == 6) return int.tryParse('FF$text', radix: 16) ?? fallback;
  if (text.length == 8) return int.tryParse(text, radix: 16) ?? fallback;
  return fallback;
}
