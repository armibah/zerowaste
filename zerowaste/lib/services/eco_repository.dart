import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_score_entry.dart';
import '../models/eco_tip.dart';
import '../models/help_issue.dart';
import '../models/impact_snapshot.dart';
import '../models/order_settings.dart';
import '../models/user_profile.dart';
import '../models/waste_record.dart';

abstract class EcoRepository {
  bool get isDemo;

  Future<List<EcoBrand>> fetchBrands();
  Future<List<EcoProduct>> fetchProducts();
  Future<List<EcoProduct>> fetchSavedProducts();
  Future<List<EcoTip>> fetchTips();
  Future<ImpactSnapshot> fetchImpactSnapshot();
  Future<UserProfile> fetchUserProfile();
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  });
  Future<UserProfile> deleteProfilePhoto();
  Future<void> setFavorite({required String productId, required bool favorite});
  Future<OrderSettings> fetchOrderSettings();
  Future<OrderSettings> updateOrderSettings(OrderSettings settings);
  Future<List<HelpIssue>> fetchHelpIssues();
  Future<HelpIssue> submitHelpIssue({
    required String subject,
    required String body,
  });
  Future<List<AppNotification>> fetchNotifications();
  Stream<List<AppNotification>> watchNotifications();
  Future<void> setNotificationRead({
    required String notificationId,
    required bool read,
  });
  Future<WasteRecord> addWasteRecord({
    required String type,
    required double amountKg,
    required int recycledItems,
    required double foodSavedKg,
    required String note,
  });
  Future<List<WasteRecord>> fetchWasteRecords();
  Future<List<EcoScoreEntry>> fetchEcoScoreHistory();
}

class SupabaseEcoRepository implements EcoRepository {
  SupabaseEcoRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isDemo => false;

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
    final products = await fetchProducts();
    return products.where((product) => product.isFavorite).toList();
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
    final userId = _requireUserIdOrNull();
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
    if (user == null) return _demoProfile;

    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .limit(1);
    if (rows.isEmpty) {
      final profile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: (user.userMetadata?['full_name'] as String?) ?? 'Eco Hero',
        avatarUrl: null,
        avatarPath: null,
      );
      await _client.from('profiles').upsert({
        'id': profile.id,
        'email': profile.email,
        'full_name': profile.fullName,
      });
      return profile;
    }

    return UserProfile.fromMap(
      Map<String, dynamic>.from(rows.first),
      email: user.email,
    );
  }

  @override
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final userId = _requireUserId();
    final current = await fetchUserProfile();
    final extension = _extensionFor(filename: filename, contentType: contentType);
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    if (current.avatarPath != null && current.avatarPath != path) {
      await _client.storage.from('avatars').remove([current.avatarPath!]);
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'email': _client.auth.currentUser?.email,
      'full_name': current.fullName,
      'avatar_url': publicUrl,
      'avatar_path': path,
      'updated_at': DateTime.now().toIso8601String(),
    });

    return current.copyWith(avatarUrl: publicUrl, avatarPath: path);
  }

  @override
  Future<UserProfile> deleteProfilePhoto() async {
    final userId = _requireUserId();
    final current = await fetchUserProfile();
    if (current.avatarPath != null) {
      await _client.storage.from('avatars').remove([current.avatarPath!]);
    }
    await _client.from('profiles').upsert({
      'id': userId,
      'email': _client.auth.currentUser?.email,
      'full_name': current.fullName,
      'avatar_url': null,
      'avatar_path': null,
      'updated_at': DateTime.now().toIso8601String(),
    });
    return current.copyWith(clearAvatar: true);
  }

  @override
  Future<void> setFavorite({
    required String productId,
    required bool favorite,
  }) async {
    final userId = _requireUserIdOrNull();
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

  @override
  Future<OrderSettings> fetchOrderSettings() async {
    final userId = _requireUserIdOrNull();
    if (userId == null) return OrderSettings.defaults();

    final rows = await _client
        .from('order_settings')
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) return OrderSettings.defaults();

    return OrderSettings.fromMap(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<OrderSettings> updateOrderSettings(OrderSettings settings) async {
    final userId = _requireUserId();
    await _client.from('order_settings').upsert({
      'user_id': userId,
      ...settings.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    return settings;
  }

  @override
  Future<List<HelpIssue>> fetchHelpIssues() async {
    final userId = _requireUserIdOrNull();
    if (userId == null) return const [];

    final rows = await _client
        .from('help_issues')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<HelpIssue>((row) => HelpIssue.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<HelpIssue> submitHelpIssue({
    required String subject,
    required String body,
  }) async {
    final userId = _requireUserId();
    final row = await _client
        .from('help_issues')
        .insert({
          'user_id': userId,
          'subject': subject,
          'body': body,
        })
        .select()
        .single();
    return HelpIssue.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final userId = _requireUserIdOrNull();
    if (userId == null) return const [];

    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<AppNotification>(
          (row) => AppNotification.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final userId = _requireUserIdOrNull();
    if (userId == null) return Stream.value(const []);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map(
          (rows) => rows
              .map<AppNotification>(
                (row) => AppNotification.fromMap(Map<String, dynamic>.from(row)),
              )
              .toList()
              .reversed
              .toList(),
        );
  }

  @override
  Future<void> setNotificationRead({
    required String notificationId,
    required bool read,
  }) async {
    await _client.from('notifications').update({
      'read_at': read ? DateTime.now().toIso8601String() : null,
    }).eq('id', notificationId);
  }

  @override
  Future<WasteRecord> addWasteRecord({
    required String type,
    required double amountKg,
    required int recycledItems,
    required double foodSavedKg,
    required String note,
  }) async {
    final userId = _requireUserId();
    final row = await _client
        .from('waste_records')
        .insert({
          'user_id': userId,
          'type': type,
          'amount_kg': amountKg,
          'recycled_items': recycledItems,
          'food_saved_kg': foodSavedKg,
          'note': note,
        })
        .select()
        .single();
    await _client.rpc('recalculate_eco_score', params: {'target_user_id': userId});
    return WasteRecord.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<WasteRecord>> fetchWasteRecords() async {
    final userId = _requireUserIdOrNull();
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
    final userId = _requireUserIdOrNull();
    if (userId == null) return _demoEcoScoreHistory;

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

  Future<Set<String>> _favoriteProductIds() async {
    final userId = _requireUserIdOrNull();
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

  String? _requireUserIdOrNull() => _client.auth.currentUser?.id;

  String _requireUserId() {
    final userId = _requireUserIdOrNull();
    if (userId == null) {
      throw StateError('You must be signed in to use this feature.');
    }
    return userId;
  }
}

class DemoEcoRepository implements EcoRepository {
  final Set<String> _favoriteIds = {'bamboo-brush'};
  UserProfile _profile = _demoProfile;
  OrderSettings _orderSettings = OrderSettings.defaults();
  final List<HelpIssue> _issues = [];
  final List<AppNotification> _notifications = [..._demoNotifications];
  final List<WasteRecord> _wasteRecords = [..._demoWasteRecords];
  ImpactSnapshot _impactSnapshot = _demoImpactSnapshot;

  @override
  bool get isDemo => true;

  @override
  Future<List<EcoBrand>> fetchBrands() async => _demoBrands;

  @override
  Future<List<EcoProduct>> fetchProducts() async {
    return _demoProducts
        .map(
          (product) => product.copyWith(
            isFavorite: _favoriteIds.contains(product.id),
          ),
        )
        .toList();
  }

  @override
  Future<List<EcoProduct>> fetchSavedProducts() async {
    final products = await fetchProducts();
    return products.where((product) => product.isFavorite).toList();
  }

  @override
  Future<List<EcoTip>> fetchTips() async => _demoTips;

  @override
  Future<ImpactSnapshot> fetchImpactSnapshot() async => _impactSnapshot;

  @override
  Future<UserProfile> fetchUserProfile() async => _profile;

  @override
  Future<UserProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    _profile = _profile.copyWith(
      avatarUrl: 'https://demo.local/avatar/$filename',
      avatarPath: 'demo/$filename',
    );
    return _profile;
  }

  @override
  Future<UserProfile> deleteProfilePhoto() async {
    _profile = _profile.copyWith(clearAvatar: true);
    return _profile;
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

  @override
  Future<OrderSettings> fetchOrderSettings() async => _orderSettings;

  @override
  Future<OrderSettings> updateOrderSettings(OrderSettings settings) async {
    _orderSettings = settings;
    return _orderSettings;
  }

  @override
  Future<List<HelpIssue>> fetchHelpIssues() async => List.unmodifiable(_issues);

  @override
  Future<HelpIssue> submitHelpIssue({
    required String subject,
    required String body,
  }) async {
    final issue = HelpIssue(
      id: 'demo-${_issues.length + 1}',
      subject: subject,
      body: body,
      status: 'open',
      createdAt: DateTime.now(),
    );
    _issues.insert(0, issue);
    return issue;
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    return List.unmodifiable(_notifications);
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return Stream.value(List.unmodifiable(_notifications));
  }

  @override
  Future<void> setNotificationRead({
    required String notificationId,
    required bool read,
  }) async {
    final index = _notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;
    final notification = _notifications[index];
    _notifications[index] = AppNotification(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      isRead: read,
      createdAt: notification.createdAt,
    );
  }

  @override
  Future<WasteRecord> addWasteRecord({
    required String type,
    required double amountKg,
    required int recycledItems,
    required double foodSavedKg,
    required String note,
  }) async {
    final record = WasteRecord(
      id: 'demo-${_wasteRecords.length + 1}',
      type: type,
      amountKg: amountKg,
      recycledItems: recycledItems,
      foodSavedKg: foodSavedKg,
      note: note,
      createdAt: DateTime.now(),
    );
    _wasteRecords.insert(0, record);
    _impactSnapshot = _calculateDemoImpact();
    return record;
  }

  @override
  Future<List<WasteRecord>> fetchWasteRecords() async {
    return List.unmodifiable(_wasteRecords);
  }

  @override
  Future<List<EcoScoreEntry>> fetchEcoScoreHistory() async {
    return _demoEcoScoreHistory;
  }

  ImpactSnapshot _calculateDemoImpact() {
    final totalWaste = _wasteRecords.fold<double>(
      0,
      (sum, record) => sum + record.amountKg,
    );
    final totalFood = _wasteRecords.fold<double>(
      0,
      (sum, record) => sum + record.foodSavedKg,
    );
    final totalRecycled = _wasteRecords.fold<int>(
      0,
      (sum, record) => sum + record.recycledItems,
    );
    final score = (55 + totalWaste * 3 + totalFood * 4 + totalRecycled).clamp(0, 100);

    return ImpactSnapshot(
      plasticWasteReduction: totalRecycled.clamp(0, 100),
      foodWasteReduction: totalFood.round().clamp(0, 100),
      packagingReduction: totalWaste.round().clamp(0, 100),
      streakDays: _impactSnapshot.streakDays + 1,
      ecoScore: score.round(),
      weeklyProgress: _impactSnapshot.weeklyProgress,
      activities: _wasteRecords
          .take(5)
          .map(
            (record) => EcoActivity(
              title: _recordTitle(record.type),
              subtitle:
                  '${record.amountKg.toStringAsFixed(1)}kg reduced, ${record.recycledItems} items recycled',
              iconName: record.type,
            ),
          )
          .toList(),
    );
  }
}

String _extensionFor({required String filename, required String contentType}) {
  final lowerName = filename.toLowerCase();
  if (lowerName.endsWith('.png') || contentType == 'image/png') return 'png';
  if (lowerName.endsWith('.webp') || contentType == 'image/webp') return 'webp';
  return 'jpg';
}

String _recordTitle(String type) {
  switch (type) {
    case 'recycle':
      return 'Recycled items';
    case 'food_saved':
      return 'Saved food';
    case 'donation':
      return 'Donated products';
    default:
      return 'Reduced waste';
  }
}

const _demoBrands = [
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

const _demoTips = [
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
    price: 28,
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
    previousPrice: 22,
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
    price: 24,
    previousPrice: 32,
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
    price: 34,
    previousPrice: null,
    ecoScore: 89,
    co2SavedKg: 3.2,
    waterSavedLiters: 22,
    material: 'Food-grade stainless steel',
    shippingNote: 'Ships in molded recycled paper',
    isFavorite: false,
  ),
];

const _demoProfile = UserProfile(
  id: 'demo-user',
  email: 'nature@example.com',
  fullName: 'Eco Hero',
  avatarUrl: null,
  avatarPath: null,
);

final _demoNotifications = [
  AppNotification(
    id: 'welcome',
    title: 'Welcome to ZeroWaste',
    body: 'Track waste, save products, and grow your Eco Score.',
    isRead: false,
    createdAt: DateTime(2026, 6, 8),
  ),
  AppNotification(
    id: 'score',
    title: 'Eco Score updated',
    body: 'Your latest recycling record improved your score.',
    isRead: true,
    createdAt: DateTime(2026, 6, 7),
  ),
];

final _demoWasteRecords = [
  WasteRecord(
    id: 'demo-1',
    type: 'recycle',
    amountKg: 2.5,
    recycledItems: 8,
    foodSavedKg: 0,
    note: 'Recycled bottles and jars',
    createdAt: DateTime(2026, 6, 8),
  ),
  WasteRecord(
    id: 'demo-2',
    type: 'food_saved',
    amountKg: 1.2,
    recycledItems: 0,
    foodSavedKg: 1.2,
    note: 'Saved leftovers for lunch',
    createdAt: DateTime(2026, 6, 7),
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

final _demoEcoScoreHistory = [
  EcoScoreEntry(
    score: 82,
    reason: 'Recycled items and reduced packaging waste',
    rankLabel: 'Top 10%',
    createdAt: DateTime(2026, 6, 8),
  ),
  EcoScoreEntry(
    score: 76,
    reason: 'Saved food and donated products',
    rankLabel: 'Top 20%',
    createdAt: DateTime(2026, 6, 1),
  ),
];
