class NftListing {
  const NftListing({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.title,
    required this.creator,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.priceEth,
    required this.lastSaleEth,
    required this.highestBidEth,
    required this.tokenId,
    required this.rarity,
    required this.chain,
    required this.endsIn,
    required this.tags,
    required this.isFavorite,
    required this.accentColor,
  });

  final String id;
  final String collectionId;
  final String collectionName;
  final String title;
  final String creator;
  final String category;
  final String description;
  final String imageUrl;
  final double priceEth;
  final double lastSaleEth;
  final double highestBidEth;
  final String tokenId;
  final String rarity;
  final String chain;
  final String endsIn;
  final List<String> tags;
  final bool isFavorite;
  final int accentColor;

  NftListing copyWith({bool? isFavorite}) {
    return NftListing(
      id: id,
      collectionId: collectionId,
      collectionName: collectionName,
      title: title,
      creator: creator,
      category: category,
      description: description,
      imageUrl: imageUrl,
      priceEth: priceEth,
      lastSaleEth: lastSaleEth,
      highestBidEth: highestBidEth,
      tokenId: tokenId,
      rarity: rarity,
      chain: chain,
      endsIn: endsIn,
      tags: tags,
      isFavorite: isFavorite ?? this.isFavorite,
      accentColor: accentColor,
    );
  }

  factory NftListing.fromMap(Map<String, dynamic> map) {
    final collection = map['nft_collections'];
    final collectionMap =
        collection is Map ? Map<String, dynamic>.from(collection) : null;
    final rawTags = map['tags'];

    return NftListing(
      id: map['id'] as String,
      collectionId: map['collection_id'] as String? ?? '',
      collectionName: collectionMap?['name'] as String? ??
          map['collection_name'] as String? ??
          'Independent drop',
      title: map['title'] as String? ?? 'Untitled NFT',
      creator: map['creator'] as String? ??
          collectionMap?['creator'] as String? ??
          'Unknown creator',
      category: map['category'] as String? ?? 'Art',
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      priceEth: _toDouble(map['price_eth']),
      lastSaleEth: _toDouble(map['last_sale_eth']),
      highestBidEth: _toDouble(map['highest_bid_eth']),
      tokenId: map['token_id'] as String? ?? '#000',
      rarity: map['rarity'] as String? ?? 'Rare',
      chain: map['chain'] as String? ?? 'Ethereum',
      endsIn: map['ends_in'] as String? ?? 'Live',
      tags: rawTags is List ? rawTags.map((tag) => '$tag').toList() : const [],
      isFavorite: map['is_favorite'] as bool? ?? false,
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
