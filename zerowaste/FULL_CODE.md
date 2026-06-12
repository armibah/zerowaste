# EcoDiscover Full Code Bundle

This single file contains the current Flutter app code, tests, and Supabase database code.

## `pubspec.yaml`

```yaml
name: zerowaste
description: "EcoDiscover, a Flutter and Supabase app for finding zero-waste products and brands."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.12.1

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  image_picker: ^1.2.2
  supabase_flutter: ^2.14.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

```

## `lib/main.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/eco_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  final repository = SupabaseConfig.isConfigured
      ? SupabaseEcoRepository(Supabase.instance.client)
      : DemoEcoRepository();
  final authService = SupabaseConfig.isConfigured
      ? SupabaseAuthService(Supabase.instance.client)
      : DemoAuthService();

  runApp(EcoDiscoverApp(repository: repository, authService: authService));
}

```

## `lib/app.dart`

```dart
import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/eco_repository.dart';

class EcoDiscoverApp extends StatelessWidget {
  const EcoDiscoverApp({
    super.key,
    required this.repository,
    required this.authService,
  });

  final EcoRepository repository;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4B7052);

    return MaterialApp(
      title: 'EcoDiscover',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          primary: seed,
          secondary: const Color(0xFFA7C08A),
          surface: const Color(0xFFFAFBF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFBF7),
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F5EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFD7DED3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFFD7DED3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: seed, width: 1.4),
          ),
        ),
      ),
      home: OnboardingScreen(repository: repository, authService: authService),
    );
  }
}

```

## `lib/config/supabase_config.dart`

```dart
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured {
    return url.isNotEmpty && anonKey.isNotEmpty;
  }
}

```

## `lib/services/auth_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthService {
  bool get isDemo;
  String? get currentEmail;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get isDemo => false;

  @override
  String? get currentEmail => _client.auth.currentUser?.email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class DemoAuthService implements AuthService {
  String? _email;

  @override
  bool get isDemo => true;

  @override
  String? get currentEmail => _email;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _email = email;
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _email = email;
  }

  @override
  Future<void> signOut() async {
    _email = null;
  }
}

```

## `lib/services/eco_repository.dart`

```dart
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

```

## `lib/models/eco_brand.dart`

```dart
class EcoBrand {
  const EcoBrand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.logoUrl,
    required this.verified,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final String logoUrl;
  final bool verified;

  factory EcoBrand.fromMap(Map<String, dynamic> map) {
    return EcoBrand(
      id: map['id'] as String,
      name: map['name'] as String,
      tagline: map['tagline'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logo_url'] as String? ?? '',
      verified: map['verified'] as bool? ?? false,
    );
  }
}

```

## `lib/models/eco_product.dart`

```dart
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
      ecoScore: map['eco_score'] as int? ?? 80,
      co2SavedKg: (map['co2_saved_kg'] as num?)?.toDouble() ?? 0,
      waterSavedLiters: map['water_saved_liters'] as int? ?? 0,
      material: map['material'] as String? ?? 'Sustainable materials',
      shippingNote:
          map['shipping_note'] as String? ?? 'Eco-conscious shipping available',
      isFavorite: map['is_favorite'] as bool? ?? false,
    );
  }
}

```

## `lib/models/eco_tip.dart`

```dart
class EcoTip {
  const EcoTip({
    required this.id,
    required this.title,
    required this.body,
    required this.iconName,
  });

  final String id;
  final String title;
  final String body;
  final String iconName;

  factory EcoTip.fromMap(Map<String, dynamic> map) {
    return EcoTip(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'eco',
    );
  }
}

```

## `lib/models/impact_snapshot.dart`

```dart
class ImpactSnapshot {
  const ImpactSnapshot({
    required this.plasticWasteReduction,
    required this.foodWasteReduction,
    required this.packagingReduction,
    required this.streakDays,
    required this.ecoScore,
    required this.totalWasteReduced,
    required this.totalRecycledItems,
    required this.totalFoodSaved,
    required this.ranking,
    required this.weeklyProgress,
    required this.monthlyStats,
    required this.activities,
    required this.scoreHistory,
  });

  final int plasticWasteReduction;
  final int foodWasteReduction;
  final int packagingReduction;
  final int streakDays;
  final int ecoScore;
  final double totalWasteReduced;
  final int totalRecycledItems;
  final double totalFoodSaved;
  final String ranking;
  final List<int> weeklyProgress;
  final List<int> monthlyStats;
  final List<EcoActivity> activities;
  final List<int> scoreHistory;

  factory ImpactSnapshot.fromMap(Map<String, dynamic> map) {
    final progress = map['weekly_progress'];
    final monthly = map['monthly_stats'];
    final activities = map['activities'];
    final history = map['score_history'];

    return ImpactSnapshot(
      plasticWasteReduction: map['plastic_waste_reduction'] as int? ?? 0,
      foodWasteReduction: map['food_waste_reduction'] as int? ?? 0,
      packagingReduction: map['packaging_reduction'] as int? ?? 0,
      streakDays: map['streak_days'] as int? ?? 0,
      ecoScore: map['eco_score'] as int? ?? 0,
      totalWasteReduced:
          (map['total_waste_reduced'] as num?)?.toDouble() ?? 0,
      totalRecycledItems: map['total_recycled_items'] as int? ?? 0,
      totalFoodSaved: (map['total_food_saved'] as num?)?.toDouble() ?? 0,
      ranking: map['ranking'] as String? ?? 'Starter',
      weeklyProgress: progress is List
          ? progress.map((value) => (value as num).round()).toList()
          : const [],
      monthlyStats: monthly is List
          ? monthly.map((value) => (value as num).round()).toList()
          : const [],
      activities: activities is List
          ? activities
              .map(
                (activity) => EcoActivity.fromMap(
                  Map<String, dynamic>.from(activity as Map),
                ),
              )
              .toList()
          : const [],
      scoreHistory: history is List
          ? history.map((value) => (value as num).round()).toList()
          : const [],
    );
  }
}

class EcoActivity {
  const EcoActivity({
    required this.title,
    required this.subtitle,
    required this.iconName,
  });

  final String title;
  final String subtitle;
  final String iconName;

  factory EcoActivity.fromMap(Map<String, dynamic> map) {
    return EcoActivity(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      iconName: map['icon_name'] as String? ?? 'eco',
    );
  }
}

```

## `lib/models/user_profile.dart`

```dart
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String avatarUrl;

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Eco Hero',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
    );
  }
}

```

## `lib/models/order_preferences.dart`

```dart
class OrderPreferences {
  const OrderPreferences({
    required this.defaultAddress,
    required this.deliveryNotes,
    required this.preferPlasticFreePackaging,
    required this.allowSubstitutions,
    required this.carbonNeutralShipping,
  });

  final String defaultAddress;
  final String deliveryNotes;
  final bool preferPlasticFreePackaging;
  final bool allowSubstitutions;
  final bool carbonNeutralShipping;

  OrderPreferences copyWith({
    String? defaultAddress,
    String? deliveryNotes,
    bool? preferPlasticFreePackaging,
    bool? allowSubstitutions,
    bool? carbonNeutralShipping,
  }) {
    return OrderPreferences(
      defaultAddress: defaultAddress ?? this.defaultAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      preferPlasticFreePackaging:
          preferPlasticFreePackaging ?? this.preferPlasticFreePackaging,
      allowSubstitutions: allowSubstitutions ?? this.allowSubstitutions,
      carbonNeutralShipping:
          carbonNeutralShipping ?? this.carbonNeutralShipping,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'default_address': defaultAddress,
      'delivery_notes': deliveryNotes,
      'prefer_plastic_free_packaging': preferPlasticFreePackaging,
      'allow_substitutions': allowSubstitutions,
      'carbon_neutral_shipping': carbonNeutralShipping,
    };
  }

  factory OrderPreferences.fromMap(Map<String, dynamic> map) {
    return OrderPreferences(
      defaultAddress: map['default_address'] as String? ?? '',
      deliveryNotes: map['delivery_notes'] as String? ?? '',
      preferPlasticFreePackaging:
          map['prefer_plastic_free_packaging'] as bool? ?? true,
      allowSubstitutions: map['allow_substitutions'] as bool? ?? true,
      carbonNeutralShipping: map['carbon_neutral_shipping'] as bool? ?? true,
    );
  }
}

```

## `lib/models/app_notification.dart`

```dart
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'EcoDiscover',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      read: map['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

```

## `lib/models/help_issue.dart`

```dart
class HelpIssue {
  const HelpIssue({
    required this.subject,
    required this.message,
    required this.contactEmail,
  });

  final String subject;
  final String message;
  final String contactEmail;

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'subject': subject,
      'message': message,
      'contact_email': contactEmail,
      'status': 'open',
    };
  }
}

```

## `lib/models/waste_record.dart`

```dart
class WasteRecord {
  const WasteRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.unit,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final String unit;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap({String? userId}) {
    return {
      if (userId != null) 'user_id': userId,
      'type': type,
      'amount': amount,
      'unit': unit,
      'note': note,
    };
  }

  factory WasteRecord.fromMap(Map<String, dynamic> map) {
    return WasteRecord(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'reduced',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'kg',
      note: map['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class EcoScoreEntry {
  const EcoScoreEntry({
    required this.id,
    required this.score,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final int score;
  final String reason;
  final DateTime createdAt;

  factory EcoScoreEntry.fromMap(Map<String, dynamic> map) {
    return EcoScoreEntry(
      id: map['id'] as String,
      score: map['score'] as int? ?? 0,
      reason: map['reason'] as String? ?? 'Eco action',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

```

## `lib/screens/onboarding_screen.dart`

```dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/eco_repository.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final EcoRepository repository;
  final AuthService authService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      title: 'Eco-friendly discovery',
      description:
          'Find plastic-free alternatives and sustainable brands that fit your lifestyle effortlessly.',
      footer: 'Welcome to your eco journey',
      icon: Icons.eco_outlined,
    ),
    _OnboardingSlide(
      title: 'Shop with confidence',
      description:
          'Browse verified makers, compare impact notes, and save your favorite zero-waste swaps.',
      footer: 'Better choices, beautifully simple',
      icon: Icons.verified_outlined,
    ),
    _OnboardingSlide(
      title: 'Build low-waste habits',
      description:
          'Get practical tips for refills, repairs, and reusable routines you can actually keep.',
      footer: 'Small swaps make a big difference',
      icon: Icons.recycling_outlined,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          repository: widget.repository,
          authService: widget.authService,
        ),
      ),
    );
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _openLogin();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primary.withValues(alpha: .18),
                    child: Icon(Icons.explore, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EcoDiscover',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _openLogin, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    return _SlideView(slide: _slides[index]);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: index == _page ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(_page == _slides.length - 1 ? 'Start' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 360),
              decoration: BoxDecoration(
                color: const Color(0xFFDDE6D7),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: 32,
                    top: 32,
                    child: Icon(
                      slide.icon,
                      size: 84,
                      color: colorScheme.primary.withValues(alpha: .28),
                    ),
                  ),
                  const Positioned(left: 44, bottom: 86, child: _Brush()),
                  Positioned(
                    right: 48,
                    bottom: 70,
                    child: _ReusableBag(color: colorScheme.primary),
                  ),
                  Positioned(
                    bottom: 52,
                    child: Container(
                      width: 84,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Icon(
                        Icons.water_drop_outlined,
                        color: colorScheme.primary,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF222921),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667064),
                height: 1.45,
              ),
        ),
        const SizedBox(height: 28),
        Text(
          '${slide.footer} - grow greener',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _Brush extends StatelessWidget {
  const _Brush();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.09,
      child: Container(
        width: 12,
        height: 122,
        decoration: BoxDecoration(
          color: const Color(0xFFC89A5D),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ReusableBag extends StatelessWidget {
  const _ReusableBag({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEE4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.local_mall_outlined, color: color, size: 40),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.footer,
    required this.icon,
  });

  final String title;
  final String description;
  final String footer;
  final IconData icon;
}

```

## `lib/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/eco_repository.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final EcoRepository repository;
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Nature Friend');
  final _emailController = TextEditingController(text: 'nature@example.com');
  final _passwordController = TextEditingController(text: 'ecodiscover');
  final _confirmPasswordController = TextEditingController(text: 'ecodiscover');

  bool _creatingAccount = true;
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_creatingAccount) {
        await widget.authService.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            repository: widget.repository,
            authService: widget.authService,
          ),
        ),
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to continue. Please check your details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showProviderMessage(String provider) {
    _showMessage('$provider sign-in can be connected in Supabase Auth.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _creatingAccount ? 'Join the Movement' : 'Welcome Back';
    final subtitle = _creatingAccount
        ? 'Embark on your journey toward a more conscious and zero-waste lifestyle.'
        : 'Continue your journey to zero waste';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _EcoHeartLogo(),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF20251F),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A7567),
                        ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.authService.isDemo) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'Demo mode: add Supabase keys to connect live auth and database.',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_creatingAccount) ...[
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Use at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          if (_creatingAccount) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords must match';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (!_creatingAccount)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showMessage(
                                  'Use Supabase Auth email recovery for production.',
                                ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          const SizedBox(height: 6),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(_creatingAccount ? 'Sign up' : 'Login'),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or continue with',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showProviderMessage('Google'),
                                  icon: const Icon(Icons.g_mobiledata),
                                  label: const Text('Google'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showProviderMessage('Apple'),
                                  icon: const Icon(Icons.apple),
                                  label: const Text('Apple'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => setState(
                      () => _creatingAccount = !_creatingAccount,
                    ),
                    child: Text(
                      _creatingAccount
                                  ? 'Already have an account? Log in'
                                  : 'New here? Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcoHeartLogo extends StatelessWidget {
  const _EcoHeartLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.favorite,
              color: const Color(0xFFF1C98C).withValues(alpha: .75),
              size: 56,
            ),
            Icon(Icons.eco, color: colorScheme.primary, size: 46),
            Positioned(
              bottom: 18,
              child: Text(
                'ECO HEART',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

```

## `lib/screens/home_screen.dart`

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_notification.dart';
import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';
import '../models/help_issue.dart';
import '../models/impact_snapshot.dart';
import '../models/order_preferences.dart';
import '../services/auth_service.dart';
import '../services/eco_repository.dart';
import '../models/user_profile.dart';
import '../models/waste_record.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final EcoRepository repository;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  List<EcoProduct> _products = [];
  List<EcoProduct> _savedProducts = [];
  List<EcoBrand> _brands = [];
  List<EcoTip> _tips = [];
  List<AppNotification> _notifications = [];
  List<WasteRecord> _wasteRecords = [];
  List<EcoScoreEntry> _scoreHistory = [];
  ImpactSnapshot? _impact;
  UserProfile? _profile;
  OrderPreferences? _orderPreferences;
  String _category = 'All';
  int _tab = 0;
  bool _loading = true;
  String? _error;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _watchNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await widget.repository.fetchProducts();
      final savedProducts = await widget.repository.fetchSavedProducts();
      final brands = await widget.repository.fetchBrands();
      final tips = await widget.repository.fetchTips();
      final impact = await widget.repository.fetchImpactSnapshot();
      final profile = await widget.repository.fetchUserProfile();
      final orderPreferences = await widget.repository.fetchOrderPreferences();
      final wasteRecords = await widget.repository.fetchWasteRecords();
      final scoreHistory = await widget.repository.fetchEcoScoreHistory();

      if (!mounted) return;
      setState(() {
        _products = products;
        _savedProducts = savedProducts;
        _brands = brands;
        _tips = tips;
        _impact = impact;
        _profile = profile;
        _orderPreferences = orderPreferences;
        _wasteRecords = wasteRecords;
        _scoreHistory = scoreHistory;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load EcoDiscover data.';
        _loading = false;
      });
    }
  }

  void _watchNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = widget.repository.watchNotifications().listen(
      (notifications) {
        if (!mounted) return;
        setState(() => _notifications = notifications);
      },
      onError: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load notifications.')),
        );
      },
    );
  }

  Future<void> _toggleFavorite(EcoProduct product) async {
    final nextFavorite = !product.isFavorite;

    setState(() {
      _products = _products
          .map(
            (item) => item.id == product.id
                ? item.copyWith(isFavorite: nextFavorite)
                : item,
          )
          .toList();
      _savedProducts = nextFavorite
          ? [
              ..._savedProducts,
              product.copyWith(isFavorite: true),
            ]
          : _savedProducts.where((item) => item.id != product.id).toList();
    });

    try {
      await widget.repository.setFavorite(
        productId: product.id,
        favorite: nextFavorite,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products = _products
            .map(
              (item) => item.id == product.id
                  ? item.copyWith(isFavorite: product.isFavorite)
                  : item,
            )
            .toList();
        _savedProducts = product.isFavorite
            ? [
                ..._savedProducts.where((item) => item.id != product.id),
                product,
              ]
            : _savedProducts.where((item) => item.id != product.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite.')),
      );
    }
  }

  Future<void> _signOut() async {
    await widget.authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          repository: widget.repository,
          authService: widget.authService,
        ),
      ),
    );
  }

  List<String> get _categories {
    final values = _products.map((product) => product.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<EcoProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      final matchesCategory = _category == 'All' || product.category == _category;
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brandName.toLowerCase().contains(query) ||
          product.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openProduct(EcoProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          similarProducts:
              _products.where((item) => item.id != product.id).take(2).toList(),
          onFavorite: () => _toggleFavorite(product),
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _showSnack('Profile photo must be smaller than 2 MB.');
        return;
      }

      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        _showSnack('Only JPG, PNG, and WEBP images are supported.');
        return;
      }

      final profile = await widget.repository.uploadProfilePhoto(
        bytes: bytes,
        extension: extension,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      _showSnack('Profile photo updated.');
    } catch (error) {
      _showSnack('Could not upload profile photo: $error');
    }
  }

  Future<void> _deleteProfilePhoto() async {
    try {
      final profile = await widget.repository.deleteProfilePhoto();
      if (!mounted) return;
      setState(() => _profile = profile);
      _showSnack('Profile photo removed.');
    } catch (error) {
      _showSnack('Could not delete profile photo: $error');
    }
  }

  Future<void> _markNotification(AppNotification notification, bool read) async {
    setState(() {
      _notifications = _notifications
          .map(
            (item) => item.id == notification.id
                ? item.copyWith(read: read)
                : item,
          )
          .toList();
    });
    try {
      await widget.repository.markNotification(
        notificationId: notification.id,
        read: read,
      );
    } catch (_) {
      _showSnack('Could not update notification.');
    }
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NotificationsSheet(
        notifications: _notifications,
        onToggleRead: _markNotification,
      ),
    );
  }

  Future<void> _openOrderSettings() async {
    final preferences = _orderPreferences;
    if (preferences == null) return;
    final updated = await Navigator.of(context).push<OrderPreferences>(
      MaterialPageRoute(
        builder: (_) => OrderSettingsScreen(
          preferences: preferences,
          onSave: widget.repository.saveOrderPreferences,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _orderPreferences = updated);
      _showSnack('Order preferences saved.');
    }
  }

  Future<void> _openHelpCenter() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HelpCenterScreen(
          email: _profile?.email ?? widget.authService.currentEmail ?? '',
          onSubmit: widget.repository.submitHelpIssue,
        ),
      ),
    );
  }

  Future<void> _addWasteRecord(WasteRecord record) async {
    try {
      await widget.repository.addWasteRecord(record);
      final impact = await widget.repository.fetchImpactSnapshot();
      final records = await widget.repository.fetchWasteRecords();
      final scoreHistory = await widget.repository.fetchEcoScoreHistory();
      if (!mounted) return;
      setState(() {
        _impact = impact;
        _wasteRecords = records;
        _scoreHistory = scoreHistory;
      });
      _showSnack('Waste tracker updated.');
    } catch (error) {
      _showSnack('Could not update waste tracker: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final impact = _impact;
    final unreadCount =
        _notifications.where((notification) => !notification.read).length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || impact == null
                  ? _ErrorState(message: _error ?? 'Missing impact data', onRetry: _load)
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _HomeTab(
                          products: _products,
                          savedProducts: _savedProducts,
                          brands: _brands,
                          tips: _tips,
                          impact: impact,
                          profile: _profile,
                          unreadCount: unreadCount,
                          onOpenProducts: () => setState(() => _tab = 1),
                          onOpenProduct: _openProduct,
                          onOpenNotifications: _openNotifications,
                          onSignOut: _signOut,
                        ),
                        _ProductsTab(
                          products: _filteredProducts,
                          searchController: _searchController,
                          categories: _categories,
                          selectedCategory: _category,
                          onSearchChanged: (_) => setState(() {}),
                          onCategoryChanged: (value) =>
                              setState(() => _category = value),
                          onFavorite: _toggleFavorite,
                          onOpenProduct: _openProduct,
                          unreadCount: unreadCount,
                          onOpenNotifications: _openNotifications,
                        ),
                        _TrackerTab(
                          impact: impact,
                          wasteRecords: _wasteRecords,
                          scoreHistory: _scoreHistory,
                          onAddRecord: _addWasteRecord,
                          unreadCount: unreadCount,
                          onOpenNotifications: _openNotifications,
                        ),
                        _MarketplaceTab(
                          products: _products,
                          brands: _brands,
                          onOpenProduct: _openProduct,
                          unreadCount: unreadCount,
                          onOpenNotifications: _openNotifications,
                        ),
                        _ProfileTab(
                          profile: _profile,
                          savedProducts: _savedProducts,
                          impact: impact,
                          orderPreferences: _orderPreferences,
                          unreadCount: unreadCount,
                          onPickPhoto: _pickProfilePhoto,
                          onDeletePhoto: _deleteProfilePhoto,
                          onOpenNotifications: _openNotifications,
                          onOpenOrderSettings: _openOrderSettings,
                          onOpenHelpCenter: _openHelpCenter,
                          onOpenSavedProduct: _openProduct,
                          onSignOut: _signOut,
                        ),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.products,
    required this.savedProducts,
    required this.brands,
    required this.tips,
    required this.impact,
    required this.profile,
    required this.unreadCount,
    required this.onOpenProducts,
    required this.onOpenProduct,
    required this.onOpenNotifications,
    required this.onSignOut,
  });

  final List<EcoProduct> products;
  final List<EcoProduct> savedProducts;
  final List<EcoBrand> brands;
  final List<EcoTip> tips;
  final ImpactSnapshot impact;
  final UserProfile? profile;
  final int unreadCount;
  final VoidCallback onOpenProducts;
  final ValueChanged<EcoProduct> onOpenProduct;
  final VoidCallback onOpenNotifications;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final featured = products.take(4).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(
                  title: 'EcoDiscover',
                  avatarUrl: profile?.avatarUrl ?? '',
                  unreadCount: unreadCount,
                  onNotifications: onOpenNotifications,
                  onSignOut: onSignOut,
                ),
                const SizedBox(height: 16),
                _SearchField(hintText: 'Search eco-friendly essentials...'),
                const SizedBox(height: 16),
                _HeroSwapCard(),
                const SizedBox(height: 18),
                _WeeklyProgressCard(impact: impact),
                const SizedBox(height: 16),
                _EcoScoreCard(score: impact.ecoScore),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Featured Products',
                  action: 'View all',
                  onAction: onOpenProducts,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = featured[index];
                return _SmallProductTile(
                  product: product,
                  onTap: () => onOpenProduct(product),
                );
              },
              childCount: featured.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: Column(
              children: [
                if (savedProducts.isNotEmpty) ...[
                  _SavedProductsPreview(
                    products: savedProducts,
                    onOpenProduct: onOpenProduct,
                  ),
                  const SizedBox(height: 12),
                ],
                if (brands.isNotEmpty) _BrandSpotlight(brand: brands.first),
                const SizedBox(height: 12),
                if (tips.isNotEmpty) _MilestoneCard(tip: tips.first),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({
    required this.products,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onFavorite,
    required this.onOpenProduct,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final List<EcoProduct> products;
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<EcoProduct> onFavorite;
  final ValueChanged<EcoProduct> onOpenProduct;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              children: [
                _TopBar(
                  title: 'EcoDiscover',
                  unreadCount: unreadCount,
                  onNotifications: onOpenNotifications,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search eco-essentials...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: Icon(Icons.tune),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: category == selectedCategory,
                        onSelected: (_) => onCategoryChanged(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Showing ${products.length} results'),
                    const Spacer(),
                    Text(
                      'Advanced Filters',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _MarketplaceProductCard(
                  product: product,
                  onFavorite: () => onFavorite(product),
                  onTap: () => onOpenProduct(product),
                );
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: .64,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackerTab extends StatelessWidget {
  const _TrackerTab({
    required this.impact,
    required this.wasteRecords,
    required this.scoreHistory,
    required this.onAddRecord,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final ImpactSnapshot impact;
  final List<WasteRecord> wasteRecords;
  final List<EcoScoreEntry> scoreHistory;
  final ValueChanged<WasteRecord> onAddRecord;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _TopBar(
              title: 'EcoDiscover',
              unreadCount: unreadCount,
              onNotifications: onOpenNotifications,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ImpactHero(impact: impact),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  children: [
                    _MetricCard(
                      icon: Icons.delete_outline,
                      label: 'Plastic Waste',
                      value: '${impact.plasticWasteReduction}%',
                    ),
                    _MetricCard(
                      icon: Icons.restaurant_outlined,
                      label: 'Food Waste',
                      value: '${impact.foodWasteReduction}%',
                    ),
                    _MetricCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Packaging',
                      value: '${impact.packagingReduction}%',
                    ),
                    _MetricCard(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Streak',
                      value: '${impact.streakDays} Days',
                      highlighted: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _WasteReductionChart(values: impact.weeklyProgress),
                const SizedBox(height: 18),
                _TrackerTotals(impact: impact),
                const SizedBox(height: 18),
                _AddWasteRecordCard(onAddRecord: onAddRecord),
                const SizedBox(height: 22),
                _ActivityList(activities: impact.activities),
                const SizedBox(height: 22),
                _EcoScoreHistory(
                  impact: impact,
                  history: scoreHistory,
                ),
                const SizedBox(height: 22),
                _WasteRecordList(records: wasteRecords),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MarketplaceTab extends StatelessWidget {
  const _MarketplaceTab({
    required this.products,
    required this.brands,
    required this.onOpenProduct,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final List<EcoProduct> products;
  final List<EcoBrand> brands;
  final ValueChanged<EcoProduct> onOpenProduct;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _TopBar(
              title: 'Marketplace',
              unreadCount: unreadCount,
              onNotifications: onOpenNotifications,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: _MarketplaceHero(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: _SectionHeader(title: 'Sustainable Brands'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _BrandCard(brand: brands[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: brands.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
            child: _SectionHeader(title: 'Best Sellers'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  child: _WideProductCard(
                    product: product,
                    onTap: () => onOpenProduct(product),
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.profile,
    required this.savedProducts,
    required this.impact,
    required this.orderPreferences,
    required this.unreadCount,
    required this.onPickPhoto,
    required this.onDeletePhoto,
    required this.onOpenNotifications,
    required this.onOpenOrderSettings,
    required this.onOpenHelpCenter,
    required this.onOpenSavedProduct,
    required this.onSignOut,
  });

  final UserProfile? profile;
  final List<EcoProduct> savedProducts;
  final ImpactSnapshot impact;
  final OrderPreferences? orderPreferences;
  final int unreadCount;
  final VoidCallback onPickPhoto;
  final VoidCallback onDeletePhoto;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenOrderSettings;
  final VoidCallback onOpenHelpCenter;
  final ValueChanged<EcoProduct> onOpenSavedProduct;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        _TopBar(
          title: 'Profile',
          avatarUrl: profile?.avatarUrl ?? '',
          unreadCount: unreadCount,
          onNotifications: onOpenNotifications,
        ),
        const SizedBox(height: 24),
        Center(
          child: _ProfileAvatar(
            avatarUrl: profile?.avatarUrl ?? '',
            radius: 48,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onPickPhoto,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload'),
            ),
            TextButton.icon(
              onPressed:
                  (profile?.avatarUrl ?? '').isEmpty ? null : onDeletePhoto,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile?.fullName ?? 'Eco Hero',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          profile?.email ?? 'nature@example.com',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 18),
        _EcoScoreCard(score: impact.ecoScore),
        const SizedBox(height: 12),
        _TrackerTotals(impact: impact),
        if (orderPreferences != null) ...[
          const SizedBox(height: 14),
          _OrderPreferencesSummary(preferences: orderPreferences!),
        ],
        const SizedBox(height: 14),
        _SavedProductsPreview(
          products: savedProducts,
          onOpenProduct: onOpenSavedProduct,
        ),
        const SizedBox(height: 14),
        _ProfileAction(
          icon: Icons.favorite_border,
          label: 'Saved Products (${savedProducts.length})',
          onTap: () {},
        ),
        _ProfileAction(
          icon: Icons.receipt_long_outlined,
          label: 'Order Settings',
          onTap: onOpenOrderSettings,
        ),
        _ProfileAction(
          icon: Icons.help_outline,
          label: 'Help Center',
          onTap: onOpenHelpCenter,
        ),
        _ProfileAction(
          icon: Icons.notifications_none,
          label: 'Notifications ($unreadCount unread)',
          onTap: onOpenNotifications,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.similarProducts,
    required this.onFavorite,
  });

  final EcoProduct product;
  final List<EcoProduct> similarProducts;
  final VoidCallback onFavorite;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _favorite = widget.product.isFavorite;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'EcoDiscover',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: _LargeProductVisual(product: product),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _money(product.price),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        _EcoBadge(score: product.ecoScore),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ShippingNote(note: product.shippingNote),
                    const SizedBox(height: 18),
                    Text(
                      'ABOUT THIS ITEM',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Material: ${product.material}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: const Text('Go to Store'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() => _favorite = !_favorite);
                            widget.onFavorite();
                          },
                          icon: Icon(
                            _favorite ? Icons.favorite : Icons.favorite_border,
                            color: _favorite ? const Color(0xFFD86B64) : color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'Similar Sustainable Picks'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final similar = widget.similarProducts[index];
                          return SizedBox(
                            width: 160,
                            child: _SmallProductTile(
                              product: similar,
                              onTap: () {},
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: widget.similarProducts.length,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    this.avatarUrl = '',
    this.unreadCount = 0,
    this.onNotifications,
    this.onSignOut,
  });

  final String title;
  final String avatarUrl;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        avatarUrl.isEmpty
            ? IconButton(
                onPressed: onSignOut,
                icon: const Icon(Icons.menu),
                visualDensity: VisualDensity.compact,
              )
            : _ProfileAvatar(avatarUrl: avatarUrl, radius: 18),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none),
              visualDensity: VisualDensity.compact,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD86B64),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl, required this.radius});

  final String avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isRemote = avatarUrl.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: .14),
      backgroundImage: isRemote ? NetworkImage(avatarUrl) : null,
      child: isRemote ? null : Icon(Icons.eco, color: color, size: radius),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _HeroSwapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9DAB5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniPill(label: 'Daily Tip'),
                const SizedBox(height: 10),
                Text(
                  'Try bees-wax wraps',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A sustainable alternative to plastic film for keeping food fresh.',
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEBC594),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined, size: 34),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.impact});

  final ImpactSnapshot impact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Progress',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              _MiniPill(label: '+${impact.streakDays}% vs last week'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Waste reduced this week',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 88, child: _MiniBarChart(values: impact.weeklyProgress)),
        ],
      ),
    );
  }
}

class _EcoScoreCard extends StatelessWidget {
  const _EcoScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .65), width: 2),
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ECO SCORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Top 5% of users',
            style: TextStyle(color: Color(0xFFE1EADB), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _SmallProductTile extends StatelessWidget {
  const _SmallProductTile({required this.product, required this.onTap});

  final EcoProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ProductVisual(product: product)),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              _money(product.price),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceProductCard extends StatelessWidget {
  const _MarketplaceProductCard({
    required this.product,
    required this.onFavorite,
    required this.onTap,
  });

  final EcoProduct product;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: _cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _ProductVisual(product: product)),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      onPressed: onFavorite,
                      icon: Icon(
                        product.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: product.isFavorite
                            ? const Color(0xFFD86B64)
                            : color,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _MiniPill(label: product.impactLabel),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(_money(product.price)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideProductCard extends StatelessWidget {
  const _WideProductCard({required this.product, required this.onTap});

  final EcoProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 24),
        child: Row(
          children: [
            SizedBox(width: 92, height: 92, child: _ProductVisual(product: product)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(product.brandName, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _money(product.price),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      _EcoBadge(score: product.ecoScore),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final EcoProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _productColor(product.category),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(product.category),
          color: const Color(0xFF3E5F45),
          size: 46,
        ),
      ),
    );
  }
}

class _LargeProductVisual extends StatelessWidget {
  const _LargeProductVisual({required this.product});

  final EcoProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFFD9E0D2),
        borderRadius: BorderRadius.circular(28),
        image: product.imageUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
      ),
      child: product.imageUrl.isEmpty
          ? Center(
              child: Icon(
                _categoryIcon(product.category),
                color: Theme.of(context).colorScheme.primary,
                size: 120,
              ),
            )
          : null,
    );
  }
}

class _ImpactHero extends StatelessWidget {
  const _ImpactHero({required this.impact});

  final ImpactSnapshot impact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impact Tracker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have saved ${impact.co2EquivalentLabel} of plastic this month. Keep it up.',
            style: const TextStyle(color: Color(0xFFE6EFE2)),
          ),
        ],
      ),
    );
  }
}

extension on ImpactSnapshot {
  String get co2EquivalentLabel {
    final total = (plasticWasteReduction + packagingReduction) / 10;
    return '${total.toStringAsFixed(1)}kg';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: highlighted ? Colors.white : primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(color: highlighted ? Colors.white : Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? Colors.white : const Color(0xFF20251F),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteReductionChart extends StatelessWidget {
  const _WasteReductionChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Waste Reduction',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              _MiniPill(label: 'Weekly'),
              const SizedBox(width: 8),
              _MiniPill(label: 'Monthly', muted: true),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 150, child: _MiniBarChart(values: values, showLabels: true)),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.values, this.showLabels = false});

  final List<int> values;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final heightFactor = values[index] / maxValue;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: heightFactor.clamp(.14, 1).toDouble(),
                    child: Container(
                      width: 22,
                      decoration: BoxDecoration(
                        color: index == 4
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFD5DDD1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabels) ...[
                const SizedBox(height: 8),
                Text(labels[index], style: const TextStyle(fontSize: 10)),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<EcoActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: 10),
        ...activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(radius: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                    child: Icon(
                      _activityIcon(activity.iconName),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          activity.subtitle,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandSpotlight extends StatelessWidget {
  const _BrandSpotlight({required this.brand});

  final EcoBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(brand.tagline, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          if (brand.verified) const Icon(Icons.verified, color: Color(0xFF4B7052)),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand});

  final EcoBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco, color: Colors.white),
          const Spacer(),
          Text(
            brand.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            brand.tagline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE6EFE2)),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.tip});

  final EcoTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Milestone: ${tip.title}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(tip.body, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E4),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop consciously',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse curated zero-waste brands, plastic-free products, and refill essentials.',
                ),
              ],
            ),
          ),
          const Icon(Icons.storefront_outlined, size: 64),
        ],
      ),
    );
  }
}

class _ShippingNote extends StatelessWidget {
  const _ShippingNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoBadge extends StatelessWidget {
  const _EcoBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted
            ? const Color(0xFFF0F2EE)
            : Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? Colors.grey[700] : Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(radius: 20),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SavedProductsPreview extends StatelessWidget {
  const _SavedProductsPreview({
    required this.products,
    required this.onOpenProduct,
  });

  final List<EcoProduct> products;
  final ValueChanged<EcoProduct> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saved Products',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text('${products.length} saved'),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Text(
              'Tap the heart on products to save them here.',
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 122,
                    child: _SmallProductTile(
                      product: product,
                      onTap: () => onOpenProduct(product),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderPreferencesSummary extends StatelessWidget {
  const _OrderPreferencesSummary({required this.preferences});

  final OrderPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Preferences',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            preferences.defaultAddress.isEmpty
                ? 'No default address set'
                : preferences.defaultAddress,
          ),
          const SizedBox(height: 6),
          Text(
            preferences.preferPlasticFreePackaging
                ? 'Plastic-free packaging preferred'
                : 'Standard packaging allowed',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({
    required this.notifications,
    required this.onToggleRead,
  });

  final List<AppNotification> notifications;
  final Future<void> Function(AppNotification notification, bool read)
      onToggleRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notifications',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No notifications yet.'),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .68,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _cardDecoration(radius: 18),
                    child: Row(
                      children: [
                        Icon(
                          notification.read
                              ? Icons.mark_email_read_outlined
                              : Icons.mark_email_unread_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(notification.body),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onToggleRead(notification, !notification.read);
                          },
                          child: Text(notification.read ? 'Unread' : 'Read'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class OrderSettingsScreen extends StatefulWidget {
  const OrderSettingsScreen({
    super.key,
    required this.preferences,
    required this.onSave,
  });

  final OrderPreferences preferences;
  final Future<OrderPreferences> Function(OrderPreferences preferences) onSave;

  @override
  State<OrderSettingsScreen> createState() => _OrderSettingsScreenState();
}

class _OrderSettingsScreenState extends State<OrderSettingsScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late OrderPreferences _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.preferences;
    _addressController =
        TextEditingController(text: widget.preferences.defaultAddress);
    _notesController =
        TextEditingController(text: widget.preferences.deliveryNotes);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        _preferences.copyWith(
          defaultAddress: _addressController.text.trim(),
          deliveryNotes: _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save order settings: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Default delivery address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Delivery notes',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _preferences.preferPlasticFreePackaging,
            onChanged: (value) => setState(
              () => _preferences =
                  _preferences.copyWith(preferPlasticFreePackaging: value),
            ),
            title: const Text('Prefer plastic-free packaging'),
          ),
          SwitchListTile(
            value: _preferences.allowSubstitutions,
            onChanged: (value) => setState(
              () => _preferences =
                  _preferences.copyWith(allowSubstitutions: value),
            ),
            title: const Text('Allow sustainable substitutions'),
          ),
          SwitchListTile(
            value: _preferences.carbonNeutralShipping,
            onChanged: (value) => setState(
              () => _preferences =
                  _preferences.copyWith(carbonNeutralShipping: value),
            ),
            title: const Text('Use carbon-neutral shipping'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save Settings'),
          ),
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({
    super.key,
    required this.email,
    required this.onSubmit,
  });

  final String email;
  final Future<void> Function(HelpIssue issue) onSubmit;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  late final TextEditingController _emailController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject and message.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        HelpIssue(
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          contactEmail: _emailController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted to support.')),
      );
      _subjectController.clear();
      _messageController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit issue: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _HelpSection(
            title: 'Contact Support',
            child: const Text(
              'Call support: 01747104029\nAvailable every day from 9 AM to 9 PM.',
            ),
          ),
          _HelpSection(
            title: 'FAQ',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Q: How do I save a product?'),
                Text('A: Tap the heart icon on any product card.'),
                SizedBox(height: 8),
                Text('Q: How is Eco Score calculated?'),
                Text('A: It updates when you reduce waste, recycle, save food, or donate.'),
                SizedBox(height: 8),
                Text('Q: Can I update order preferences?'),
                Text('A: Yes, open Profile > Order Settings.'),
              ],
            ),
          ),
          _HelpSection(
            title: 'Live Support',
            child: const Text(
              'Live support is available by phone now. In-app chat can be connected later through Supabase Edge Functions or a support provider.',
            ),
          ),
          _HelpSection(
            title: 'Report Issue',
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Contact email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Submitting...' : 'Submit Issue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TrackerTotals extends StatelessWidget {
  const _TrackerTotals({required this.impact});

  final ImpactSnapshot impact;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: .95,
      children: [
        _TotalTile(
          label: 'Waste reduced',
          value: '${impact.totalWasteReduced.toStringAsFixed(1)}kg',
        ),
        _TotalTile(
          label: 'Recycled',
          value: '${impact.totalRecycledItems}',
        ),
        _TotalTile(
          label: 'Food saved',
          value: '${impact.totalFoodSaved.toStringAsFixed(1)}kg',
        ),
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AddWasteRecordCard extends StatefulWidget {
  const _AddWasteRecordCard({required this.onAddRecord});

  final ValueChanged<WasteRecord> onAddRecord;

  @override
  State<_AddWasteRecordCard> createState() => _AddWasteRecordCardState();
}

class _AddWasteRecordCardState extends State<_AddWasteRecordCard> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'reduced';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }
    widget.onAddRecord(
      WasteRecord(
        id: '',
        type: _type,
        amount: amount,
        unit: _type == 'recycled' || _type == 'donated' ? 'items' : 'kg',
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _amountController.clear();
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Waste Tracker Record',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Action type'),
            items: const [
              DropdownMenuItem(value: 'reduced', child: Text('Reduced waste')),
              DropdownMenuItem(value: 'recycled', child: Text('Recycled items')),
              DropdownMenuItem(value: 'food_saved', child: Text('Saved food')),
              DropdownMenuItem(value: 'donated', child: Text('Donated products')),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == 'recycled' || _type == 'donated'
                  ? 'Amount (items)'
                  : 'Amount (kg)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoScoreHistory extends StatelessWidget {
  const _EcoScoreHistory({required this.impact, required this.history});

  final ImpactSnapshot impact;
  final List<EcoScoreEntry> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Eco Score History',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              _MiniPill(label: impact.ranking),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: _MiniBarChart(
              values: impact.scoreHistory.isEmpty
                  ? history.map((entry) => entry.score).toList()
                  : impact.scoreHistory,
            ),
          ),
          const SizedBox(height: 10),
          ...history.take(3).map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text('${entry.score} points'),
                  subtitle: Text(entry.reason),
                ),
              ),
        ],
      ),
    );
  }
}

class _WasteRecordList extends StatelessWidget {
  const _WasteRecordList({required this.records});

  final List<WasteRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waste Records',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(
              'Add a record to start automatic monthly tracking.',
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            ...records.take(5).map(
                  (record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_activityIcon(record.type)),
                    title: Text(_recordTitle(record.type)),
                    subtitle: Text(record.note.isEmpty ? record.unit : record.note),
                    trailing: Text('${record.amount.toStringAsFixed(1)} ${record.unit}'),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 140),
        const Icon(Icons.cloud_off_outlined, size: 54),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

BoxDecoration _cardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .045),
        blurRadius: 20,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

Color _productColor(String category) {
  return switch (category) {
    'Cleaning' => const Color(0xFFD5DFD1),
    'Drinkware' => const Color(0xFFE3D1AD),
    'Grocery' => const Color(0xFFF1E4CD),
    'Kitchen' => const Color(0xFFE6D9C2),
    'Personal Care' => const Color(0xFFDCE8D7),
    _ => const Color(0xFFEAF0E4),
  };
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Cleaning' => Icons.cleaning_services_outlined,
    'Drinkware' => Icons.coffee_outlined,
    'Grocery' => Icons.shopping_basket_outlined,
    'Kitchen' => Icons.kitchen_outlined,
    'Personal Care' => Icons.spa_outlined,
    _ => Icons.eco_outlined,
  };
}

IconData _activityIcon(String iconName) {
  return switch (iconName) {
    'bag' => Icons.shopping_bag_outlined,
    'bottle' => Icons.water_drop_outlined,
    'compost' => Icons.compost_outlined,
    'donated' => Icons.volunteer_activism_outlined,
    'food_saved' => Icons.restaurant_outlined,
    'recycled' => Icons.recycling_outlined,
    'reduced' => Icons.delete_sweep_outlined,
    _ => Icons.eco_outlined,
  };
}

String _recordTitle(String type) {
  return switch (type) {
    'donated' => 'Donated products',
    'food_saved' => 'Saved food',
    'recycled' => 'Recycled items',
    'reduced' => 'Reduced waste',
    _ => 'Eco action',
  };
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

```

## `test/widget_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/app.dart';
import 'package:zerowaste/services/auth_service.dart';
import 'package:zerowaste/services/eco_repository.dart';

void main() {
  testWidgets('shows EcoDiscover onboarding', (tester) async {
    await tester.pumpWidget(
      EcoDiscoverApp(
        repository: DemoEcoRepository(),
        authService: DemoAuthService(),
      ),
    );

    expect(find.text('EcoDiscover'), findsOneWidget);
    expect(find.text('Eco-friendly discovery'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('can open the sign-up screen from onboarding', (tester) async {
    await tester.pumpWidget(
      EcoDiscoverApp(
        repository: DemoEcoRepository(),
        authService: DemoAuthService(),
      ),
    );

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Join the Movement'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('nature@example.com'), findsOneWidget);
  });
}

```

## `supabase/schema.sql`

```sql
-- EcoDiscover Supabase schema
-- Run this file in the Supabase SQL editor or with `supabase db push`.

create extension if not exists "pgcrypto";

create table if not exists public.eco_brands (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  tagline text not null default '',
  description text not null default '',
  logo_url text not null default '',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.eco_products (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid references public.eco_brands(id) on delete set null,
  slug text not null unique,
  name text not null,
  category text not null,
  description text not null default '',
  impact_label text not null default 'Low waste',
  image_url text not null default '',
  tags text[] not null default '{}',
  price numeric(10, 2) not null default 0,
  previous_price numeric(10, 2),
  eco_score integer not null default 80 check (eco_score between 0 and 100),
  co2_saved_kg numeric(10, 2) not null default 0,
  water_saved_liters integer not null default 0,
  material text not null default 'Sustainable materials',
  shipping_note text not null default 'Eco-conscious shipping available',
  created_at timestamptz not null default now()
);

create table if not exists public.eco_tips (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  body text not null default '',
  icon_name text not null default 'eco',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.eco_products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.impact_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plastic_waste_reduction integer not null default 70,
  food_waste_reduction integer not null default 45,
  packaging_reduction integer not null default 90,
  streak_days integer not null default 15,
  eco_score integer not null default 82 check (eco_score between 0 and 100),
  total_waste_reduced numeric(10, 2) not null default 0,
  total_recycled_items integer not null default 0,
  total_food_saved numeric(10, 2) not null default 0,
  ranking text not null default 'Starter',
  weekly_progress integer[] not null default array[18, 22, 38, 30, 52, 41, 64],
  monthly_stats integer[] not null default array[0, 0, 0, 0, 0, 0],
  score_history integer[] not null default array[82],
  activities jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Eco Hero',
  email text not null default '',
  avatar_url text not null default '',
  avatar_path text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.saved_products (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.eco_products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.order_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  default_address text not null default '',
  delivery_notes text not null default '',
  prefer_plastic_free_packaging boolean not null default true,
  allow_substitutions boolean not null default true,
  carbon_neutral_shipping boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.support_issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  subject text not null,
  message text not null,
  contact_email text not null default '',
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  type text not null default 'general',
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.waste_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('reduced', 'recycled', 'food_saved', 'donated')),
  amount numeric(10, 2) not null check (amount > 0),
  unit text not null default 'kg',
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.eco_score_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score between 0 and 100),
  reason text not null default 'Eco action',
  created_at timestamptz not null default now()
);

alter table public.eco_products
  add column if not exists price numeric(10, 2) not null default 0,
  add column if not exists previous_price numeric(10, 2),
  add column if not exists eco_score integer not null default 80,
  add column if not exists co2_saved_kg numeric(10, 2) not null default 0,
  add column if not exists water_saved_liters integer not null default 0,
  add column if not exists material text not null default 'Sustainable materials',
  add column if not exists shipping_note text not null default 'Eco-conscious shipping available';

alter table public.impact_snapshots
  add column if not exists total_waste_reduced numeric(10, 2) not null default 0,
  add column if not exists total_recycled_items integer not null default 0,
  add column if not exists total_food_saved numeric(10, 2) not null default 0,
  add column if not exists ranking text not null default 'Starter',
  add column if not exists monthly_stats integer[] not null default array[0, 0, 0, 0, 0, 0],
  add column if not exists score_history integer[] not null default array[82];

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create index if not exists saved_products_user_idx
  on public.saved_products (user_id, created_at desc);
create index if not exists notifications_user_read_idx
  on public.notifications (user_id, read, created_at desc);
create index if not exists waste_records_user_created_idx
  on public.waste_records (user_id, created_at desc);
create index if not exists eco_score_history_user_created_idx
  on public.eco_score_history (user_id, created_at desc);

alter table public.notifications replica identity full;

alter table public.eco_brands enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_tips enable row level security;
alter table public.user_favorites enable row level security;
alter table public.impact_snapshots enable row level security;
alter table public.user_profiles enable row level security;
alter table public.saved_products enable row level security;
alter table public.order_preferences enable row level security;
alter table public.support_issues enable row level security;
alter table public.notifications enable row level security;
alter table public.waste_records enable row level security;
alter table public.eco_score_history enable row level security;

drop policy if exists "Eco brands are readable by everyone" on public.eco_brands;
create policy "Eco brands are readable by everyone"
  on public.eco_brands for select
  to anon, authenticated
  using (true);

drop policy if exists "Eco products are readable by everyone" on public.eco_products;
create policy "Eco products are readable by everyone"
  on public.eco_products for select
  to anon, authenticated
  using (true);

drop policy if exists "Eco tips are readable by everyone" on public.eco_tips;
create policy "Eco tips are readable by everyone"
  on public.eco_tips for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can read their own favorites" on public.user_favorites;
create policy "Users can read their own favorites"
  on public.user_favorites for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can add their own favorites" on public.user_favorites;
create policy "Users can add their own favorites"
  on public.user_favorites for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can remove their own favorites" on public.user_favorites;
create policy "Users can remove their own favorites"
  on public.user_favorites for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read their own impact snapshot" on public.impact_snapshots;
create policy "Users can read their own impact snapshot"
  on public.impact_snapshots for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can upsert their own impact snapshot" on public.impact_snapshots;
create policy "Users can upsert their own impact snapshot"
  on public.impact_snapshots for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own impact snapshot" on public.impact_snapshots;
create policy "Users can update their own impact snapshot"
  on public.impact_snapshots for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can read their own profile" on public.user_profiles;
create policy "Users can read their own profile"
  on public.user_profiles for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own profile" on public.user_profiles;
create policy "Users can create their own profile"
  on public.user_profiles for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own profile" on public.user_profiles;
create policy "Users can update their own profile"
  on public.user_profiles for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can read saved products" on public.saved_products;
create policy "Users can read saved products"
  on public.saved_products for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can save products" on public.saved_products;
create policy "Users can save products"
  on public.saved_products for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can unsave products" on public.saved_products;
create policy "Users can unsave products"
  on public.saved_products for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read order preferences" on public.order_preferences;
create policy "Users can read order preferences"
  on public.order_preferences for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert order preferences" on public.order_preferences;
create policy "Users can insert order preferences"
  on public.order_preferences for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update order preferences" on public.order_preferences;
create policy "Users can update order preferences"
  on public.order_preferences for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can create support issues" on public.support_issues;
create policy "Users can create support issues"
  on public.support_issues for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can read their support issues" on public.support_issues;
create policy "Users can read their support issues"
  on public.support_issues for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read notifications" on public.notifications;
create policy "Users can read notifications"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can update notifications" on public.notifications;
create policy "Users can update notifications"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can read waste records" on public.waste_records;
create policy "Users can read waste records"
  on public.waste_records for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can add waste records" on public.waste_records;
create policy "Users can add waste records"
  on public.waste_records for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update waste records" on public.waste_records;
create policy "Users can update waste records"
  on public.waste_records for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete waste records" on public.waste_records;
create policy "Users can delete waste records"
  on public.waste_records for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read score history" on public.eco_score_history;
create policy "Users can read score history"
  on public.eco_score_history for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can upload profile photos" on storage.objects;
create policy "Users can upload profile photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update profile photos" on storage.objects;
create policy "Users can update profile photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete profile photos" on storage.objects;
create policy "Users can delete profile photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Profile photos are publicly readable" on storage.objects;
create policy "Profile photos are publicly readable"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'profile-photos');

create or replace function public.create_default_impact_snapshot()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (user_id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Eco Hero'),
    coalesce(new.email, '')
  )
  on conflict (user_id) do nothing;

  insert into public.order_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.impact_snapshots (
    user_id,
    plastic_waste_reduction,
    food_waste_reduction,
    packaging_reduction,
    streak_days,
    eco_score,
    weekly_progress,
    activities
  )
  values (
    new.id,
    70,
    45,
    90,
    15,
    82,
    array[18, 22, 38, 30, 52, 41, 64],
    '[
      {
        "title": "Refilled water bottle",
        "subtitle": "Today, saved 2 plastic bottles",
        "icon_name": "bottle"
      },
      {
        "title": "Composted food scraps",
        "subtitle": "Yesterday, 0.5kg waste diverted",
        "icon_name": "compost"
      },
      {
        "title": "Used reusable bag",
        "subtitle": "June 3, avoided 4 bags",
        "icon_name": "bag"
      }
    ]'::jsonb
  )
  on conflict (user_id) do nothing;

  insert into public.notifications (user_id, title, body, type)
  values
    (
      new.id,
      'Welcome to EcoDiscover',
      'Your profile, tracker, and marketplace are ready.',
      'general'
    ),
    (
      new.id,
      'Eco Score started',
      'Add waste, recycling, food-saving, or donation records to grow your score.',
      'score'
    );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_impact_snapshot on auth.users;
create trigger on_auth_user_created_create_impact_snapshot
  after insert on auth.users
  for each row execute function public.create_default_impact_snapshot();

create or replace function public.recalculate_user_impact(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  reduced_total numeric(10, 2);
  recycled_total integer;
  food_total numeric(10, 2);
  donated_total integer;
  next_score integer;
  next_ranking text;
  next_weekly integer[];
  next_monthly integer[];
begin
  select
    coalesce(sum(amount) filter (where type = 'reduced'), 0),
    coalesce(sum(amount) filter (where type = 'recycled'), 0)::integer,
    coalesce(sum(amount) filter (where type = 'food_saved'), 0),
    coalesce(sum(amount) filter (where type = 'donated'), 0)::integer
  into reduced_total, recycled_total, food_total, donated_total
  from public.waste_records
  where user_id = target_user_id;

  next_score := least(
    100,
    greatest(
      0,
      round(50 + reduced_total * 1.2 + recycled_total * 0.5 + food_total * 2 + donated_total * 3)
    )
  )::integer;

  next_ranking := case
    when next_score >= 90 then 'Top 5%'
    when next_score >= 80 then 'Top 10%'
    when next_score >= 70 then 'Top 20%'
    else 'Growing'
  end;

  next_weekly := array[
    least(100, greatest(0, round(reduced_total)::integer)),
    least(100, greatest(0, recycled_total)),
    least(100, greatest(0, round(food_total * 2)::integer)),
    least(100, greatest(0, donated_total * 4)),
    least(100, greatest(0, next_score - 12)),
    least(100, greatest(0, next_score - 6)),
    next_score
  ];

  select array_agg(score order by created_at)
  into next_monthly
  from (
    select score, created_at
    from public.eco_score_history
    where user_id = target_user_id
    order by created_at desc
    limit 6
  ) recent_scores;

  if next_monthly is null or array_length(next_monthly, 1) = 0 then
    next_monthly := array[next_score];
  end if;

  insert into public.impact_snapshots (
    user_id,
    plastic_waste_reduction,
    food_waste_reduction,
    packaging_reduction,
    streak_days,
    eco_score,
    total_waste_reduced,
    total_recycled_items,
    total_food_saved,
    ranking,
    weekly_progress,
    monthly_stats,
    score_history,
    activities,
    updated_at
  )
  values (
    target_user_id,
    least(100, round(reduced_total * 4)::integer),
    least(100, round(food_total * 8)::integer),
    least(100, recycled_total * 2),
    greatest(1, (select count(*) from public.waste_records where user_id = target_user_id)),
    next_score,
    reduced_total,
    recycled_total,
    food_total,
    next_ranking,
    next_weekly,
    next_monthly,
    next_monthly,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title',
            case type
              when 'reduced' then 'Reduced waste'
              when 'recycled' then 'Recycled items'
              when 'food_saved' then 'Saved food'
              when 'donated' then 'Donated products'
              else 'Eco action'
            end,
            'subtitle',
            amount || ' ' || unit || case when note <> '' then ' - ' || note else '' end,
            'icon_name',
            type
          )
          order by created_at desc
        )
        from (
          select type, amount, unit, note, created_at
          from public.waste_records
          where user_id = target_user_id
          order by created_at desc
          limit 5
        ) latest_records
      ),
      '[]'::jsonb
    ),
    now()
  )
  on conflict (user_id) do update set
    plastic_waste_reduction = excluded.plastic_waste_reduction,
    food_waste_reduction = excluded.food_waste_reduction,
    packaging_reduction = excluded.packaging_reduction,
    streak_days = excluded.streak_days,
    eco_score = excluded.eco_score,
    total_waste_reduced = excluded.total_waste_reduced,
    total_recycled_items = excluded.total_recycled_items,
    total_food_saved = excluded.total_food_saved,
    ranking = excluded.ranking,
    weekly_progress = excluded.weekly_progress,
    monthly_stats = excluded.monthly_stats,
    score_history = excluded.score_history,
    activities = excluded.activities,
    updated_at = now();

  insert into public.eco_score_history (user_id, score, reason)
  values (target_user_id, next_score, 'Automatic Eco Score recalculation');

  insert into public.notifications (user_id, title, body, type)
  values (
    target_user_id,
    'Eco Score updated',
    'Your Eco Score is now ' || next_score || ' (' || next_ranking || ').',
    'score'
  );
end;
$$;

create or replace function public.on_waste_record_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recalculate_user_impact(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists waste_records_recalculate_impact on public.waste_records;
create trigger waste_records_recalculate_impact
  after insert or update or delete on public.waste_records
  for each row execute function public.on_waste_record_changed();

insert into public.eco_brands (slug, name, tagline, description, verified)
values
  (
    'refill-home',
    'Refill Home',
    'Reusable home essentials',
    'Durable jars, refill stations, and low-waste kitchen staples for everyday households.',
    true
  ),
  (
    'root-and-fiber',
    'Root & Fiber',
    'Compostable personal care',
    'Plant-based personal care products packed in recyclable paper and compostable materials.',
    true
  ),
  (
    'loop-market',
    'Loop Market',
    'Circular groceries',
    'Local groceries delivered in returnable containers with pickup built into every order.',
    false
  )
on conflict (slug) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  verified = excluded.verified;

insert into public.eco_products (
  brand_id,
  slug,
  name,
  category,
  description,
  impact_label,
  tags,
  price,
  previous_price,
  eco_score,
  co2_saved_kg,
  water_saved_liters,
  material,
  shipping_note
)
values
  (
    (select id from public.eco_brands where slug = 'root-and-fiber'),
    'bamboo-brush',
    'Bamboo Toothbrush Kit',
    'Personal Care',
    'A soft-bristle toothbrush with a bamboo handle and recyclable travel sleeve.',
    'Plastic-free handle',
    array['bamboo', 'travel', 'compostable'],
    12.99,
    16.99,
    88,
    1.80,
    24,
    'Moso bamboo and plant-based bristles',
    'Ships in recyclable paper packaging'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'glass-pantry-jars',
    'Stackable Glass Pantry Jars',
    'Kitchen',
    'Airtight jars for bulk grains, snacks, and refills with replaceable silicone seals.',
    'Reusable for years',
    array['glass', 'bulk', 'kitchen'],
    28.00,
    null,
    92,
    2.40,
    38,
    'Recycled glass and food-grade silicone',
    'Carbon-neutral shipping on bundles'
  ),
  (
    (select id from public.eco_brands where slug = 'loop-market'),
    'cotton-produce-bags',
    'Organic Cotton Produce Bags',
    'Grocery',
    'Washable drawstring bags sized for produce, bread, and small pantry refills.',
    'Replaces thin plastic bags',
    array['cotton', 'grocery', 'washable'],
    18.50,
    22.00,
    84,
    1.10,
    18,
    'GOTS organic cotton mesh',
    'Packed without plastic mailers'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'solid-dish-block',
    'Solid Dish Soap Block',
    'Cleaning',
    'Concentrated dish soap block that ships without water or plastic bottles.',
    'Bottle-free cleaning',
    array['cleaning', 'soap', 'refill'],
    9.99,
    null,
    90,
    1.60,
    42,
    'Plant oils, mineral scrub, paper wrap',
    'Minimal paper wrap and recycled carton'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'bamboo-travel-mug',
    'Premium Bamboo Travel Mug',
    'Drinkware',
    'A durable, BPA-free travel mug made from organic bamboo fibers. Keeps drinks hot for 6 hours and fits standard cup holders.',
    'Eco',
    array['bamboo', 'coffee', 'reusable'],
    24.00,
    32.00,
    94,
    2.80,
    57,
    'Bamboo fiber, recycled steel, silicone lid',
    'Plastic-free shipping and compostable ink labels'
  ),
  (
    (select id from public.eco_brands where slug = 'loop-market'),
    'steel-bento',
    'Steel Bento Lunch Box',
    'Kitchen',
    'Leak-resistant stainless bento for meal prep, takeout, and low-waste lunches.',
    'Reusable lunch kit',
    array['steel', 'meal prep', 'lunch'],
    34.00,
    null,
    89,
    3.20,
    22,
    'Food-grade stainless steel',
    'Ships in molded recycled paper'
  )
on conflict (slug) do update set
  brand_id = excluded.brand_id,
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  impact_label = excluded.impact_label,
  tags = excluded.tags,
  price = excluded.price,
  previous_price = excluded.previous_price,
  eco_score = excluded.eco_score,
  co2_saved_kg = excluded.co2_saved_kg,
  water_saved_liters = excluded.water_saved_liters,
  material = excluded.material,
  shipping_note = excluded.shipping_note;

insert into public.eco_tips (slug, title, body, icon_name, sort_order)
values
  (
    'swap-one',
    'Start with one daily swap',
    'Pick the single-use item you touch most often, then replace it with one reusable option.',
    'leaf',
    10
  ),
  (
    'bulk-list',
    'Bring a refill list',
    'Keep a small note of pantry staples so bulk shopping stays quick and low-stress.',
    'jar',
    20
  ),
  (
    'repair-first',
    'Repair before replacing',
    'Small fixes extend product life and usually save more impact than buying a greener replacement.',
    'repair',
    30
  )
on conflict (slug) do update set
  title = excluded.title,
  body = excluded.body,
  icon_name = excluded.icon_name,
  sort_order = excluded.sort_order;

```
