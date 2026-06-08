import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/market_activity.dart';
import '../models/nft_collection.dart';
import '../models/nft_listing.dart';
import '../models/portfolio_snapshot.dart';

abstract class MarketplaceRepository {
  Future<List<NftCollection>> fetchCollections();
  Future<List<NftListing>> fetchListings();
  Future<List<MarketActivity>> fetchActivities();
  Future<PortfolioSnapshot> fetchPortfolioSnapshot();
  Future<void> setFavorite({
    required String listingId,
    required bool favorite,
  });
}

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  SupabaseMarketplaceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<NftCollection>> fetchCollections() async {
    final rows = await _client
        .from('nft_collections')
        .select()
        .order('volume_eth', ascending: false);
    return rows
        .map<NftCollection>(
          (row) => NftCollection.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<List<NftListing>> fetchListings() async {
    final rows = await _client
        .from('nft_listings')
        .select('*, nft_collections(name, creator)')
        .order('created_at', ascending: false);
    final favoriteIds = await _favoriteListingIds();

    return rows.map<NftListing>((row) {
      final listing = NftListing.fromMap(Map<String, dynamic>.from(row));
      return listing.copyWith(isFavorite: favoriteIds.contains(listing.id));
    }).toList();
  }

  @override
  Future<List<MarketActivity>> fetchActivities() async {
    final rows = await _client
        .from('nft_market_activities')
        .select()
        .order('created_at', ascending: false)
        .limit(8);
    return rows
        .map<MarketActivity>(
          (row) => MarketActivity.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<PortfolioSnapshot> fetchPortfolioSnapshot() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _demoPortfolioSnapshot;

    final rows = await _client
        .from('nft_portfolios')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return _demoPortfolioSnapshot;

    return PortfolioSnapshot.fromMap(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<void> setFavorite({
    required String listingId,
    required bool favorite,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (favorite) {
      await _client.from('user_watchlist').upsert({
        'user_id': userId,
        'listing_id': listingId,
      });
      return;
    }

    await _client.from('user_watchlist').delete().match({
      'user_id': userId,
      'listing_id': listingId,
    });
  }

  Future<Set<String>> _favoriteListingIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await _client
        .from('user_watchlist')
        .select('listing_id')
        .eq('user_id', userId);
    return rows
        .map<String>(
          (row) => Map<String, dynamic>.from(row)['listing_id'] as String,
        )
        .toSet();
  }
}

class DemoMarketplaceRepository implements MarketplaceRepository {
  final Set<String> _favoriteIds = {'azuki-sky-214'};

  @override
  Future<List<NftCollection>> fetchCollections() async => _demoCollections;

  @override
  Future<List<NftListing>> fetchListings() async {
    return _demoListings
        .map(
          (listing) => listing.copyWith(
            isFavorite: _favoriteIds.contains(listing.id),
          ),
        )
        .toList();
  }

  @override
  Future<List<MarketActivity>> fetchActivities() async => _demoActivities;

  @override
  Future<PortfolioSnapshot> fetchPortfolioSnapshot() async {
    return _demoPortfolioSnapshot;
  }

  @override
  Future<void> setFavorite({
    required String listingId,
    required bool favorite,
  }) async {
    if (favorite) {
      _favoriteIds.add(listingId);
    } else {
      _favoriteIds.remove(listingId);
    }
  }
}

const _demoCollections = [
  NftCollection(
    id: 'nova-apes',
    name: 'Nova Apes',
    creator: 'Orbit Studio',
    description:
        'Cyber primates forged from interstellar chrome, neon fur, and reactive moonlight.',
    category: 'PFP',
    floorPriceEth: 3.42,
    volumeEth: 12800,
    items: 7777,
    verified: true,
    accentColor: 0xFF8B5CF6,
  ),
  NftCollection(
    id: 'neon-samurai',
    name: 'Neon Samurai',
    creator: 'Yuki Labs',
    description:
        'Animated warriors carrying ancestral armor into a synthetic Tokyo night market.',
    category: 'Gaming',
    floorPriceEth: 1.88,
    volumeEth: 7640,
    items: 4200,
    verified: true,
    accentColor: 0xFF06B6D4,
  ),
  NftCollection(
    id: 'dream-orbit',
    name: 'Dream Orbit',
    creator: 'Mira Chen',
    description:
        'Meditative generative worlds made from soft gradients and impossible architecture.',
    category: 'Art',
    floorPriceEth: 0.74,
    volumeEth: 3890,
    items: 2500,
    verified: false,
    accentColor: 0xFFFF7A59,
  ),
];

const _demoListings = [
  NftListing(
    id: 'azuki-sky-214',
    collectionId: 'nova-apes',
    collectionName: 'Nova Apes',
    title: 'Ape Nebula #214',
    creator: 'Orbit Studio',
    category: 'PFP',
    description:
        'A one-of-one chrome ape with violet plasma fur, starfield visor, and animated nebula jacket.',
    imageUrl: '',
    priceEth: 4.82,
    lastSaleEth: 4.10,
    highestBidEth: 4.55,
    tokenId: '#214',
    rarity: 'Legendary',
    chain: 'Ethereum',
    endsIn: '06h 24m',
    tags: ['chrome', 'animated', 'nebula'],
    isFavorite: true,
    accentColor: 0xFF8B5CF6,
  ),
  NftListing(
    id: 'samurai-88',
    collectionId: 'neon-samurai',
    collectionName: 'Neon Samurai',
    title: 'Ronin Pulse #88',
    creator: 'Yuki Labs',
    category: 'Gaming',
    description:
        'Playable neon ronin with a reactive blade, rare shadow mask, and arena-ready loadout.',
    imageUrl: '',
    priceEth: 2.16,
    lastSaleEth: 1.94,
    highestBidEth: 2.05,
    tokenId: '#88',
    rarity: 'Epic',
    chain: 'Polygon',
    endsIn: '11h 09m',
    tags: ['playable', 'mask', 'katana'],
    isFavorite: false,
    accentColor: 0xFF06B6D4,
  ),
  NftListing(
    id: 'orbit-512',
    collectionId: 'dream-orbit',
    collectionName: 'Dream Orbit',
    title: 'Glass Planet #512',
    creator: 'Mira Chen',
    category: 'Art',
    description:
        'A tranquil orbital habitat suspended over a sunrise gradient, rendered from generative glass forms.',
    imageUrl: '',
    priceEth: 0.92,
    lastSaleEth: 0.80,
    highestBidEth: 0.86,
    tokenId: '#512',
    rarity: 'Rare',
    chain: 'Base',
    endsIn: '1d 03h',
    tags: ['generative', 'glass', 'orbit'],
    isFavorite: false,
    accentColor: 0xFFFF7A59,
  ),
  NftListing(
    id: 'nova-990',
    collectionId: 'nova-apes',
    collectionName: 'Nova Apes',
    title: 'Signal Ape #990',
    creator: 'Orbit Studio',
    category: 'PFP',
    description:
        'Deep-space broadcaster with holographic headphones and a constellation frequency pack.',
    imageUrl: '',
    priceEth: 3.37,
    lastSaleEth: 3.02,
    highestBidEth: 3.18,
    tokenId: '#990',
    rarity: 'Super Rare',
    chain: 'Ethereum',
    endsIn: '2d 12h',
    tags: ['audio', 'hologram', 'space'],
    isFavorite: false,
    accentColor: 0xFFA855F7,
  ),
  NftListing(
    id: 'samurai-301',
    collectionId: 'neon-samurai',
    collectionName: 'Neon Samurai',
    title: 'Mecha Guard #301',
    creator: 'Yuki Labs',
    category: 'Gaming',
    description:
        'Guardian-class samurai with metallic kabuto, teal aura, and clan reward utility.',
    imageUrl: '',
    priceEth: 1.48,
    lastSaleEth: 1.22,
    highestBidEth: 1.36,
    tokenId: '#301',
    rarity: 'Rare',
    chain: 'Polygon',
    endsIn: '03h 42m',
    tags: ['utility', 'guard', 'teal'],
    isFavorite: false,
    accentColor: 0xFF14B8A6,
  ),
  NftListing(
    id: 'orbit-43',
    collectionId: 'dream-orbit',
    collectionName: 'Dream Orbit',
    title: 'Aurora Gate #43',
    creator: 'Mira Chen',
    category: 'Art',
    description:
        'Pastel portal study with a cinematic aurora pass, architectural silhouettes, and dreamy haze.',
    imageUrl: '',
    priceEth: 1.05,
    lastSaleEth: 0.97,
    highestBidEth: 1.00,
    tokenId: '#43',
    rarity: 'Rare',
    chain: 'Base',
    endsIn: '18h 17m',
    tags: ['aurora', 'portal', 'pastel'],
    isFavorite: false,
    accentColor: 0xFFF97316,
  ),
];

const _demoActivities = [
  MarketActivity(
    title: 'Ape Nebula #214 listed',
    subtitle: 'Orbit Studio opened the auction',
    valueEth: 4.82,
    iconName: 'sell',
  ),
  MarketActivity(
    title: 'Ronin Pulse #88 bid',
    subtitle: 'Highest bid increased 12%',
    valueEth: 2.05,
    iconName: 'bolt',
  ),
  MarketActivity(
    title: 'Glass Planet #512 sold',
    subtitle: 'Collected by @northstar',
    valueEth: 0.80,
    iconName: 'verified',
  ),
];

const _demoPortfolioSnapshot = PortfolioSnapshot(
  balanceEth: 12.48,
  portfolioValueEth: 28.74,
  watchlistCount: 9,
  createdCount: 3,
  trendingScores: [34, 52, 47, 66, 72, 61, 88],
  activities: _demoActivities,
);
