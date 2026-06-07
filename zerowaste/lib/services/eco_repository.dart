import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';
import '../models/impact_snapshot.dart';

abstract class EcoRepository {
  Future<List<EcoBrand>> fetchBrands();
  Future<List<EcoProduct>> fetchProducts();
  Future<List<EcoTip>> fetchTips();
  Future<ImpactSnapshot> fetchImpactSnapshot();
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
  Future<ImpactSnapshot> fetchImpactSnapshot() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _demoImpactSnapshot;

    final rows = await _client
        .from('impact_snapshots')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return _demoImpactSnapshot;

    return ImpactSnapshot.fromMap(Map<String, dynamic>.from(rows.first));
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
  Future<ImpactSnapshot> fetchImpactSnapshot() async {
    return _demoImpactSnapshot;
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
    price: 12.99,
    previousPrice: 16.99,
    ecoScore: 88,
    co2SavedKg: 1.8,
    waterSavedLiters: 24,
    material: 'Moso bamboo and plant-based bristles',
    shippingNote: 'Ships in recyclable paper packaging',
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
    price: 28.00,
    previousPrice: null,
    ecoScore: 92,
    co2SavedKg: 2.4,
    waterSavedLiters: 38,
    material: 'Recycled glass and food-grade silicone',
    shippingNote: 'Carbon-neutral shipping on bundles',
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
    price: 18.50,
    previousPrice: 22.00,
    ecoScore: 84,
    co2SavedKg: 1.1,
    waterSavedLiters: 18,
    material: 'GOTS organic cotton mesh',
    shippingNote: 'Packed without plastic mailers',
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
    price: 9.99,
    previousPrice: null,
    ecoScore: 90,
    co2SavedKg: 1.6,
    waterSavedLiters: 42,
    material: 'Plant oils, mineral scrub, paper wrap',
    shippingNote: 'Minimal paper wrap and recycled carton',
    isFavorite: false,
  ),
  EcoProduct(
    id: 'bamboo-travel-mug',
    brandId: 'refill-home',
    brandName: 'Refill Home',
    name: 'Premium Bamboo Travel Mug',
    category: 'Drinkware',
    description:
        'A durable, BPA-free travel mug made from organic bamboo fibers. Keeps drinks hot for 6 hours and fits standard cup holders.',
    impactLabel: 'Eco',
    imageUrl: '',
    tags: ['bamboo', 'coffee', 'reusable'],
    price: 24.00,
    previousPrice: 32.00,
    ecoScore: 94,
    co2SavedKg: 2.8,
    waterSavedLiters: 57,
    material: 'Bamboo fiber, recycled steel, silicone lid',
    shippingNote: 'Plastic-free shipping and compostable ink labels',
    isFavorite: false,
  ),
  EcoProduct(
    id: 'steel-bento',
    brandId: 'loop-market',
    brandName: 'Loop Market',
    name: 'Steel Bento Lunch Box',
    category: 'Kitchen',
    description:
        'Leak-resistant stainless bento for meal prep, takeout, and low-waste lunches.',
    impactLabel: 'Reusable lunch kit',
    imageUrl: '',
    tags: ['steel', 'meal prep', 'lunch'],
    price: 34.00,
    previousPrice: null,
    ecoScore: 89,
    co2SavedKg: 3.2,
    waterSavedLiters: 22,
    material: 'Food-grade stainless steel',
    shippingNote: 'Ships in molded recycled paper',
    isFavorite: false,
  ),
];

const _demoImpactSnapshot = ImpactSnapshot(
  plasticWasteReduction: 70,
  foodWasteReduction: 45,
  packagingReduction: 90,
  streakDays: 15,
  ecoScore: 82,
  weeklyProgress: [18, 22, 38, 30, 52, 41, 64],
  activities: [
    EcoActivity(
      title: 'Refilled water bottle',
      subtitle: 'Today, saved 2 plastic bottles',
      iconName: 'bottle',
    ),
    EcoActivity(
      title: 'Composted food scraps',
      subtitle: 'Yesterday, 0.5kg waste diverted',
      iconName: 'compost',
    ),
    EcoActivity(
      title: 'Used reusable bag',
      subtitle: 'June 3, avoided 4 bags',
      iconName: 'bag',
    ),
  ],
);
