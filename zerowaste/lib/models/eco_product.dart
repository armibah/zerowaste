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
      isFavorite: map['is_favorite'] as bool? ?? false,
    );
  }
}