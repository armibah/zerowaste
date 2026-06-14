import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';
import '../models/help_issue.dart';
import '../models/impact_snapshot.dart';
import '../models/order_preferences.dart';
import '../models/user_profile.dart';
import '../models/waste_record.dart';

abstract class EcoRepository {
  Future<List<EcoBrand>> fetchBrands();
  Future<List<EcoProduct>> fetchProducts();
  Future<List<EcoProduct>> fetchSavedProducts();
  Future<List<EcoTip>> fetchTips();
  Future<ImpactSnapshot> fetchImpactSnapshot();
  Future<UserProfile> fetchUserProfile();
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension,
  });
  Future<UserProfile> deleteProfilePhoto();
  Future<OrderPreferences> fetchOrderPreferences();
  Future<OrderPreferences> saveOrderPreferences(OrderPreferences preferences);
  Stream<List<AppNotification>> watchNotifications();
  Future<void> markNotification({
    required String notificationId,
    required bool read,
  });
  Future<void> submitHelpIssue(HelpIssue issue);
  Future<void> addWasteRecord(WasteRecord record);
  Future<List<WasteRecord>> fetchWasteRecords();
  Future<List<EcoScoreEntry>> fetchEcoScoreHistory();
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
  Future<List<EcoProduct>> fetchSavedProducts() async {
    final favoriteIds = await _favoriteProductIds();
    if (favoriteIds.isEmpty) return [];

    final products = await fetchProducts();
    return products.where((product) => favoriteIds.contains(product.id)).toList();
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
  Future<UserProfile> fetchUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const UserProfile(
        userId: '',
        fullName: 'Eco Hero',
        email: '',
        avatarUrl: '',
      );
    }

    final rows = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isNotEmpty) {
      return UserProfile.fromMap(Map<String, dynamic>.from(rows.first));
    }

    final profile = {
      'user_id': user.id,
      'full_name': user.userMetadata?['full_name'] as String? ?? 'Eco Hero',
      'email': user.email ?? '',
      'avatar_url': '',
      'avatar_path': '',
    };
    final inserted = await _client
        .from('user_profiles')
        .upsert(profile)
        .select()
        .single();
    return UserProfile.fromMap(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Please sign in to upload a profile photo.');
    }

    final normalizedExtension = extension.toLowerCase().replaceAll('.', '');
    final contentType = switch (normalizedExtension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw Exception('Only JPG, PNG, and WEBP images are supported.'),
    };
    final path =
        '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    final currentProfile = await _profileRow(user.id);
    final oldPath = currentProfile?['avatar_path'] as String?;

    await _client.storage.from('profile-photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
    final avatarUrl = _client.storage.from('profile-photos').getPublicUrl(path);

    final currentEmail = currentProfile?['email'] as String?;
    final updated = await _client
        .from('user_profiles')
        .upsert({
          'user_id': user.id,
          'full_name':
              currentProfile?['full_name'] as String? ?? 'Eco Hero',
          'email': user.email ?? currentEmail ?? '',
          'avatar_url': avatarUrl,
          'avatar_path': path,
        })
        .select()
        .single();

    if (oldPath != null && oldPath.isNotEmpty && oldPath != path) {
      await _client.storage.from('profile-photos').remove([oldPath]);
    }

    return UserProfile.fromMap(Map<String, dynamic>.from(updated));
  }

  @override
  Future<UserProfile> deleteProfilePhoto() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Please sign in to delete a profile photo.');
    }

    final currentProfile = await _profileRow(user.id);
    final oldPath = currentProfile?['avatar_path'] as String?;
    if (oldPath != null && oldPath.isNotEmpty) {
      await _client.storage.from('profile-photos').remove([oldPath]);
    }

    final updated = await _client
        .from('user_profiles')
        .update({'avatar_url': '', 'avatar_path': ''})
        .eq('user_id', user.id)
        .select()
        .single();
    return UserProfile.fromMap(Map<String, dynamic>.from(updated));
  }

  @override
  Future<OrderPreferences> fetchOrderPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _demoOrderPreferences;

    final rows = await _client
        .from('order_preferences')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return _demoOrderPreferences;
    return OrderPreferences.fromMap(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<OrderPreferences> saveOrderPreferences(
    OrderPreferences preferences,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Please sign in to save order settings.');
    }

    final row = await _client
        .from('order_preferences')
        .upsert(preferences.toMap(userId: userId))
        .select()
        .single();
    return OrderPreferences.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map<AppNotification>(
                (row) => AppNotification.fromMap(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  @override
  Future<void> markNotification({
    required String notificationId,
    required bool read,
  }) async {
    await _client
        .from('notifications')
        .update({'read': read})
        .eq('id', notificationId);
  }

  @override
  Future<void> submitHelpIssue(HelpIssue issue) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('support_issues').insert(issue.toMap(userId: userId));
  }

  @override
  Future<void> addWasteRecord(WasteRecord record) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('Please sign in to update your waste tracker.');
    }

    await _client.from('waste_records').insert(record.toMap(userId: userId));
  }

  @override
  Future<List<WasteRecord>> fetchWasteRecords() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('waste_records')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<WasteRecord>(
          (row) => WasteRecord.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<List<EcoScoreEntry>> fetchEcoScoreHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return _demoScoreHistory;

    final rows = await _client
        .from('eco_score_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    return rows
        .map<EcoScoreEntry>(
          (row) => EcoScoreEntry.fromMap(Map<String, dynamic>.from(row)),
        )
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
      await _client.from('saved_products').upsert({
        'user_id': userId,
        'product_id': productId,
      });
      return;
    }

    await _client.from('user_favorites').delete().match({
      'user_id': userId,
      'product_id': productId,
    });
    await _client.from('saved_products').delete().match({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<Set<String>> _favoriteProductIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await _client
        .from('saved_products')
        .select('product_id')
        .eq('user_id', userId);
    return rows
        .map<String>(
          (row) => Map<String, dynamic>.from(row)['product_id'] as String,
        )
        .toSet();
  }

  Future<Map<String, dynamic>?> _profileRow(String userId) async {
    final rows = await _client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }
}

class DemoEcoRepository implements EcoRepository {
  final Set<String> _favoriteIds = {'bamboo-brush'};
  UserProfile _profile = const UserProfile(
    userId: 'demo-user',
    fullName: 'Eco Hero',
    email: 'nature@example.com',
    avatarUrl: '',
  );
  OrderPreferences _orderPreferences = _demoOrderPreferences;
  List<AppNotification> _notifications = _demoNotifications;
  final List<WasteRecord> _wasteRecords = [];
  List<EcoScoreEntry> _scoreHistory = _demoScoreHistory;

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
  Future<List<EcoProduct>> fetchSavedProducts() async {
    final products = await fetchProducts();
    return products.where((product) => product.isFavorite).toList();
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
    return _impactFromDemoRecords();
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    return _profile;
  }

  @override
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = extension.toLowerCase().replaceAll('.', '');
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(normalizedExtension)) {
      throw Exception('Only JPG, PNG, and WEBP images are supported.');
    }
    _profile = _profile.copyWith(
      avatarUrl: 'demo://profile-photo/${bytes.length}.$normalizedExtension',
    );
    return _profile;
  }

  @override
  Future<UserProfile> deleteProfilePhoto() async {
    _profile = _profile.copyWith(avatarUrl: '');
    return _profile;
  }

  @override
  Future<OrderPreferences> fetchOrderPreferences() async {
    return _orderPreferences;
  }

  @override
  Future<OrderPreferences> saveOrderPreferences(
    OrderPreferences preferences,
  ) async {
    _orderPreferences = preferences;
    return _orderPreferences;
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return Stream.value(_notifications);
  }

  @override
  Future<void> markNotification({
    required String notificationId,
    required bool read,
  }) async {
    _notifications = _notifications
        .map(
          (notification) => notification.id == notificationId
              ? notification.copyWith(read: read)
              : notification,
        )
        .toList();
  }

  @override
  Future<void> submitHelpIssue(HelpIssue issue) async {
    _notifications = [
      AppNotification(
        id: 'support-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Support request received',
        body: 'We received "${issue.subject}" and will contact you soon.',
        type: 'support',
        read: false,
        createdAt: DateTime.now(),
      ),
      ..._notifications,
    ];
  }

  @override
  Future<void> addWasteRecord(WasteRecord record) async {
    final created = WasteRecord(
      id: 'record-${DateTime.now().millisecondsSinceEpoch}',
      type: record.type,
      amount: record.amount,
      unit: record.unit,
      note: record.note,
      createdAt: DateTime.now(),
    );
    _wasteRecords.insert(0, created);
    _scoreHistory = [
      EcoScoreEntry(
        id: 'score-${DateTime.now().millisecondsSinceEpoch}',
        score: _impactFromDemoRecords().ecoScore,
        reason: 'Added ${record.type} record',
        createdAt: DateTime.now(),
      ),
      ..._scoreHistory,
    ];
  }

  @override
  Future<List<WasteRecord>> fetchWasteRecords() async {
    return _wasteRecords;
  }

  @override
  Future<List<EcoScoreEntry>> fetchEcoScoreHistory() async {
    return _scoreHistory;
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

  ImpactSnapshot _impactFromDemoRecords() {
    final reduced = _wasteRecords
        .where((record) => record.type == 'reduced')
        .fold<double>(14, (total, record) => total + record.amount);
    final recycled = _wasteRecords
        .where((record) => record.type == 'recycled')
        .fold<int>(32, (total, record) => total + record.amount.round());
    final foodSaved = _wasteRecords
        .where((record) => record.type == 'food_saved')
        .fold<double>(5, (total, record) => total + record.amount);
    final donated = _wasteRecords
        .where((record) => record.type == 'donated')
        .fold<int>(2, (total, record) => total + record.amount.round());
    final score = (70 + reduced * 1.2 + recycled * .4 + foodSaved * 2 + donated * 3)
        .round()
        .clamp(0, 100)
        .toInt();
    final activities = _wasteRecords
        .take(3)
        .map(
          (record) => EcoActivity(
            title: _recordTitle(record.type),
            subtitle: '${record.amount.toStringAsFixed(1)} ${record.unit}',
            iconName: record.type,
          ),
        )
        .toList();

    return ImpactSnapshot(
      plasticWasteReduction: (reduced * 4).round().clamp(0, 100).toInt(),
      foodWasteReduction: (foodSaved * 8).round().clamp(0, 100).toInt(),
      packagingReduction: (recycled * 2).round().clamp(0, 100).toInt(),
      streakDays: 15 + _wasteRecords.length,
      ecoScore: score,
      totalWasteReduced: reduced,
      totalRecycledItems: recycled,
      totalFoodSaved: foodSaved,
      ranking: score >= 90
          ? 'Top 5%'
          : score >= 75
              ? 'Top 15%'
              : 'Growing',
      weeklyProgress: [18, 22, 38, 30, 52, 41 + _wasteRecords.length, 64],
      monthlyStats: [42, 48, 56, 61, 72, score],
      activities: activities.isEmpty ? _demoImpactSnapshot.activities : activities,
      scoreHistory: _scoreHistory.take(6).map((entry) => entry.score).toList(),
    );
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

const _demoOrderPreferences = OrderPreferences(
  defaultAddress: 'House 12, Green Road, Dhaka',
  deliveryNotes: 'Leave orders at the front desk if I am unavailable.',
  preferPlasticFreePackaging: true,
  allowSubstitutions: true,
  carbonNeutralShipping: true,
);

final _demoNotifications = [
  AppNotification(
    id: 'welcome',
    title: 'Welcome to EcoDiscover',
    body: 'Your zero-waste dashboard is ready.',
    type: 'general',
    read: false,
    createdAt: DateTime(2026, 6, 12, 10),
  ),
  AppNotification(
    id: 'score',
    title: 'Eco Score updated',
    body: 'You reached the top 15% of users this week.',
    type: 'score',
    read: false,
    createdAt: DateTime(2026, 6, 12, 9),
  ),
  AppNotification(
    id: 'saved',
    title: 'Saved product reminder',
    body: 'Your bamboo travel mug is still available.',
    type: 'saved',
    read: true,
    createdAt: DateTime(2026, 6, 11, 18),
  ),
];

final _demoScoreHistory = [
  EcoScoreEntry(
    id: 'score-1',
    score: 82,
    reason: 'Reduced household waste',
    createdAt: DateTime(2026, 6, 12),
  ),
  EcoScoreEntry(
    id: 'score-2',
    score: 78,
    reason: 'Recycled 8 items',
    createdAt: DateTime(2026, 6, 6),
  ),
  EcoScoreEntry(
    id: 'score-3',
    score: 73,
    reason: 'Saved food scraps',
    createdAt: DateTime(2026, 5, 29),
  ),
];

const _demoImpactSnapshot = ImpactSnapshot(
  plasticWasteReduction: 70,
  foodWasteReduction: 45,
  packagingReduction: 90,
  streakDays: 15,
  ecoScore: 82,
  totalWasteReduced: 14,
  totalRecycledItems: 32,
  totalFoodSaved: 5,
  ranking: 'Top 15%',
  weeklyProgress: [18, 22, 38, 30, 52, 41, 64],
  monthlyStats: [42, 48, 56, 61, 72, 82],
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
  scoreHistory: [63, 68, 72, 76, 78, 82],
);

String _recordTitle(String type) {
  return switch (type) {
    'donated' => 'Donated products',
    'food_saved' => 'Saved food',
    'recycled' => 'Recycled items',
    'reduced' => 'Reduced waste',
    _ => 'Eco action',
  };
}
