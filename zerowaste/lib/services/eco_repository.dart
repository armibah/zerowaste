import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';

abstract class EcoRepository {
  Future<List<EcoBrand>> fetchBrands();
  Future<List<EcoProduct>> fetchProducts();
  Future<List<EcoTip>> fetchTips();
  Future<void> setFavorite({required String productId, required bool favorite});
}

class SupabaseEcoRepository implements EcoRepository {
  SupabaseEcoRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EcoBrand>> fetchBrands() async {
    final rows = await _client.from('eco_brands').select().order('name');
    return rows
        .map<EcoBrand>((row) => EcoBrand.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<List<EcoProduct>> fetchProducts() async {
    final rows = await _client
        .from('eco_products')
        .select('*, eco_brands(name)')
        .order('name');
    final favoriteIds = await _favoriteProductIds();

    return rows.map<EcoProduct>((row) {
      final product = EcoProduct.fromMap(Map<String, dynamic>.from(row));
      return product.copyWith(isFavorite: favoriteIds.contains(product.id));
    }).toList();
  }

  @override
  Future<List<EcoTip>> fetchTips() async {
    final rows = await _client.from('eco_tips').select().order('sort_order');
    return rows
        .map<EcoTip>((row) => EcoTip.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<void> setFavorite({
    required String productId,
    required bool favorite,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (favorite) {
      await _client.from('user_favorites').upsert({
        'user_id': userId,
        'product_id': productId,
      });
      return;
    }

    await _client.from('user_favorites').delete().match({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<Set<String>> _favoriteProductIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await _client
        .from('user_favorites')
        .select('product_id')
        .eq('user_id', userId);
    return rows
        .map<String>(
          (row) => Map<String, dynamic>.from(row)['product_id'] as String,
        )
        .toSet();
  }
}

class DemoEcoRepository implements EcoRepository {
  final Set<String> _favoriteIds = {'bamboo-brush'};

  @override
  Future<List<EcoBrand>> fetchBrands() async {
    return const [
      EcoBrand(
        id: 'refill-home',
        name: 'Refill Home',
        tagline: 'Reusable home essentials',
        description:
            'A verified marketplace for durable jars, refill stations, and low-waste kitchen staples.',
        logoUrl: '',
        verified: true,
      ),
      EcoBrand(
        id: 'root-and-fiber',
        name: 'Root & Fiber',
        tagline: 'Compostable personal care',
        description:
            'Personal care products made with plant-based materials and recyclable paper packaging.',
        logoUrl: '',
        verified: true,
      ),
      EcoBrand(
        id: 'loop-market',
        name: 'Loop Market',
        tagline: 'Circular groceries',
        description:
            'Local groceries delivered in returnable containers with pickup built into every order.',
        logoUrl: '',
        verified: false,
      ),
    ];
  }

  @override
  Future<List<EcoProduct>> fetchProducts() async {
    final products = _demoProducts
        .map((product) => product.copyWith(
              isFavorite: _favoriteIds.contains(product.id),
            ))
        .toList();
    return products;
  }

  @override
  Future<List<EcoTip>> fetchTips() async {
    return const [
      EcoTip(
        id: 'swap-one',
        title: 'Start with one daily swap',
        body:
            'Pick the single-use item you touch most often, then replace it with one reusable option.',
        iconName: 'leaf',
      ),
      EcoTip(
        id: 'bulk-list',
        title: 'Bring a refill list',
        body:
            'Keep a small note of pantry staples so bulk shopping stays quick and low-stress.',
        iconName: 'jar',
      ),
      EcoTip(
        id: 'repair-first',
        title: 'Repair before replacing',
        body:
            'Small fixes extend product life and usually save more impact than buying a greener replacement.',
        iconName: 'repair',
      ),
    ];
  }

  @override
  Future<void> setFavorite({
    required String productId,
    required bool favorite,
  }) async {
    if (favorite) {
      _favoriteIds.add(productId);
    } else {
      _favoriteIds.remove(productId);
    }
  }
}

const _demoProducts = [
  EcoProduct(
    id: 'bamboo-brush',
    brandId: 'root-and-fiber',
    brandName: 'Root & Fiber',
    name: 'Bamboo Toothbrush Kit',
    category: 'Personal Care',
    description:
        'A soft-bristle toothbrush with a bamboo handle and recyclable travel sleeve.',
    impactLabel: 'Plastic-free handle',
    imageUrl: '',
    tags: ['bamboo', 'travel', 'compostable'],
    isFavorite: true,
  ),
  EcoProduct(
    id: 'glass-pantry-jars',
    brandId: 'refill-home',
    brandName: 'Refill Home',
    name: 'Stackable Glass Pantry Jars',
    category: 'Kitchen',
    description:
        'Airtight jars for bulk grains, snacks, and refills with replaceable silicone seals.',
    impactLabel: 'Reusable for years',
    imageUrl: '',
    tags: ['glass', 'bulk', 'kitchen'],
    isFavorite: false,
  ),
  EcoProduct(
    id: 'cotton-produce-bags',
    brandId: 'loop-market',
    brandName: 'Loop Market',
    name: 'Organic Cotton Produce Bags',
    category: 'Grocery',
    description:
        'Washable drawstring bags sized for produce, bread, and small pantry refills.',
    impactLabel: 'Replaces thin plastic bags',
    imageUrl: '',
    tags: ['cotton', 'grocery', 'washable'],
    isFavorite: false,
  ),
  EcoProduct(
    id: 'solid-dish-block',
    brandId: 'refill-home',
    brandName: 'Refill Home',
    name: 'Solid Dish Soap Block',
    category: 'Cleaning',
    description:
        'Concentrated dish soap block that ships without water or plastic bottles.',
    impactLabel: 'Bottle-free cleaning',
    imageUrl: '',
    tags: ['cleaning', 'soap', 'refill'],
    isFavorite: false,
  ),
];
