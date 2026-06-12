class EcoProduct {
  const EcoProduct({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.category,
    required this.description,
    required this.impactLabel,
    required this.imageUrl,
    required this.tags,
    required this.price,
    required this.previousPrice,
    required this.ecoScore,
    required this.co2SavedKg,
    required this.waterSavedLiters,
    required this.material,
    required this.shippingNote,
    required this.isFavorite,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final String category;
  final String description;
  final String impactLabel;
  final String imageUrl;
  final List<String> tags;
  final double price;
  final double? previousPrice;
  final int ecoScore;
  final double co2SavedKg;
  final int waterSavedLiters;
  final String material;
  final String shippingNote;
  final bool isFavorite;

  EcoProduct copyWith({bool? isFavorite}) {
    return EcoProduct(
      id: id,
      brandId: brandId,
      brandName: brandName,
      name: name,
      category: category,
      description: description,
      impactLabel: impactLabel,
      imageUrl: imageUrl,
      tags: tags,
      price: price,
      previousPrice: previousPrice,
      ecoScore: ecoScore,
      co2SavedKg: co2SavedKg,
      waterSavedLiters: waterSavedLiters,
      material: material,
      shippingNote: shippingNote,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory EcoProduct.fromMap(Map<String, dynamic> map) {
    final brand = map['eco_brands'];
    final brandMap = brand is Map ? Map<String, dynamic>.from(brand) : null;
    final nestedBrandName = brandMap?['name'] as String?;
    final fallbackBrandName = map['brand_name'] as String?;
    final brandName = nestedBrandName ?? fallbackBrandName ?? 'Independent maker';
    final rawTags = map['tags'];

    return EcoProduct(
      id: map['id'] as String,
      brandId: map['brand_id'] as String? ?? '',
      brandName: brandName,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'General',
      description: map['description'] as String? ?? '',
      impactLabel: map['impact_label'] as String? ?? 'Low waste',
      imageUrl: map['image_url'] as String? ?? '',
      tags: rawTags is List ? rawTags.map((tag) => '$tag').toList() : const [],
      price: (map['price'] as num?)?.toDouble() ?? 0,
      previousPrice: (map['previous_price'] as num?)?.toDouble(),
      ecoScore: (map['eco_score'] as num?)?.toInt() ?? 0,
      co2SavedKg: (map['co2_saved_kg'] as num?)?.toDouble() ?? 0,
      waterSavedLiters: (map['water_saved_liters'] as num?)?.toInt() ?? 0,
      material: map['material'] as String? ?? '',
      shippingNote: map['shipping_note'] as String? ?? '',
      isFavorite: map['is_favorite'] as bool? ?? false,
    );
  }
}
