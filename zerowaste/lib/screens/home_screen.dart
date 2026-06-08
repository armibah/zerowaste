import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_notification.dart';
import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_score_entry.dart';
import '../models/eco_tip.dart';
import '../models/impact_snapshot.dart';
import '../models/order_settings.dart';
import '../models/user_profile.dart';
import '../models/waste_record.dart';
import '../services/auth_service.dart';
import '../services/eco_repository.dart';
import 'login_screen.dart';

const _supportPhone = '01747104029';

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
  final _picker = ImagePicker();

  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  List<EcoProduct> _products = [];
  List<EcoBrand> _brands = [];
  List<EcoTip> _tips = [];
  List<AppNotification> _notifications = [];
  List<WasteRecord> _wasteRecords = [];
  List<EcoScoreEntry> _scoreHistory = [];
  ImpactSnapshot? _impact;
  UserProfile? _profile;
  String _category = 'All';
  int _tab = 0;
  bool _loading = true;
  bool _avatarLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _notificationSubscription = widget.repository.watchNotifications().listen(
      (notifications) {
        if (!mounted) return;
        setState(() => _notifications = notifications);
      },
      onError: (_) {},
    );
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
      final brands = await widget.repository.fetchBrands();
      final tips = await widget.repository.fetchTips();
      final impact = await widget.repository.fetchImpactSnapshot();
      final profile = await widget.repository.fetchUserProfile();
      final notifications = await widget.repository.fetchNotifications();
      final wasteRecords = await widget.repository.fetchWasteRecords();
      final scoreHistory = await widget.repository.fetchEcoScoreHistory();

      if (!mounted) return;
      setState(() {
        _products = products;
        _brands = brands;
        _tips = tips;
        _impact = impact;
        _profile = profile;
        _notifications = notifications;
        _wasteRecords = wasteRecords;
        _scoreHistory = scoreHistory;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load ZeroWaste data. $error';
        _loading = false;
      });
    }
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

  List<EcoProduct> get _savedProducts {
    return _products.where((product) => product.isFavorite).toList();
  }

  int get _unreadNotificationCount {
    return _notifications.where((notification) => !notification.isRead).length;
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
    });

    try {
      await widget.repository.setFavorite(
        productId: product.id,
        favorite: nextFavorite,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _products = _products
            .map(
              (item) => item.id == product.id
                  ? item.copyWith(isFavorite: product.isFavorite)
                  : item,
            )
            .toList();
      });
      _showMessage('Could not update saved product. $error');
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final contentType = image.mimeType ?? _contentTypeFor(image.name);
      final validationError = _validateImage(bytes.length, contentType);
      if (validationError != null) {
        _showMessage(validationError);
        return;
      }

      setState(() => _avatarLoading = true);
      final profile = await widget.repository.uploadProfilePhoto(
        bytes: bytes,
        filename: image.name,
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() => _profile = profile);
      _showMessage('Profile photo updated.');
    } catch (error) {
      _showMessage('Could not upload profile photo. $error');
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      setState(() => _avatarLoading = true);
      final profile = await widget.repository.deleteProfilePhoto();
      if (!mounted) return;
      setState(() => _profile = profile);
      _showMessage('Profile photo removed.');
    } catch (error) {
      _showMessage('Could not delete profile photo. $error');
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  Future<void> _addWasteRecord() async {
    final record = await showModalBottomSheet<_WasteRecordDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WasteRecordSheet(),
    );
    if (record == null) return;

    try {
      await widget.repository.addWasteRecord(
        type: record.type,
        amountKg: record.amountKg,
        recycledItems: record.recycledItems,
        foodSavedKg: record.foodSavedKg,
        note: record.note,
      );
      await _load();
      _showMessage('Waste tracker updated automatically.');
    } catch (error) {
      _showMessage('Could not add waste record. $error');
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(repository: widget.repository),
      ),
    );
    await _load();
  }

  Future<void> _openSavedProducts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavedProductsScreen(
          repository: widget.repository,
          onOpenProduct: _openProduct,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openOrderSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSettingsScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _openHelpCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HelpCenterScreen(repository: widget.repository),
      ),
    );
  }

  void _openProduct(EcoProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          similarProducts:
              _products.where((item) => item.id != product.id).take(3).toList(),
          onFavorite: () => _toggleFavorite(product),
        ),
      ),
    );
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final impact = _impact;
    final profile = _profile;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || impact == null || profile == null
                  ? _ErrorState(
                      message: _error ?? 'Missing dashboard data.',
                      onRetry: _load,
                    )
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _DashboardTab(
                          products: _products,
                          brands: _brands,
                          tips: _tips,
                          impact: impact,
                          profile: profile,
                          unreadCount: _unreadNotificationCount,
                          onNotifications: _openNotifications,
                          onOpenProducts: () => setState(() => _tab = 1),
                          onOpenProduct: _openProduct,
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
                        ),
                        _TrackerTab(
                          impact: impact,
                          wasteRecords: _wasteRecords,
                          scoreHistory: _scoreHistory,
                          onAddRecord: _addWasteRecord,
                        ),
                        _MarketplaceTab(
                          products: _products,
                          brands: _brands,
                          onOpenProduct: _openProduct,
                        ),
                        _ProfileTab(
                          profile: profile,
                          impact: impact,
                          savedProducts: _savedProducts,
                          avatarLoading: _avatarLoading,
                          onPickAvatar: _pickAvatar,
                          onDeleteAvatar: _deleteAvatar,
                          onOpenSavedProducts: _openSavedProducts,
                          onOpenOrderSettings: _openOrderSettings,
                          onOpenHelpCenter: _openHelpCenter,
                          onOpenProduct: _openProduct,
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
            label: 'Market',
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

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.products,
    required this.brands,
    required this.tips,
    required this.impact,
    required this.profile,
    required this.unreadCount,
    required this.onNotifications,
    required this.onOpenProducts,
    required this.onOpenProduct,
  });

  final List<EcoProduct> products;
  final List<EcoBrand> brands;
  final List<EcoTip> tips;
  final ImpactSnapshot impact;
  final UserProfile profile;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onOpenProducts;
  final ValueChanged<EcoProduct> onOpenProduct;

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
                  title: 'ZeroWaste',
                  unreadCount: unreadCount,
                  onNotifications: onNotifications,
                ),
                const SizedBox(height: 16),
                _HeroCard(profile: profile, tip: tips.isEmpty ? null : tips.first),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Waste reduced',
                        value: '${impact.totalWasteReduced} kg',
                        icon: Icons.delete_sweep_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Eco score',
                        value: '${impact.ecoScore}',
                        icon: Icons.eco_outlined,
                      ),
                    ),
                  ],
                ),
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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = featured[index];
                return _ProductCard(
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
              childAspectRatio: .76,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              children: [
                if (brands.isNotEmpty) _BrandSpotlight(brand: brands.first),
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
  });

  final List<EcoProduct> products;
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<EcoProduct> onFavorite;
  final ValueChanged<EcoProduct> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              children: [
                const _TopBar(title: 'Products'),
                const SizedBox(height: 14),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search eco-friendly essentials...',
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
                return _ProductCard(
                  product: product,
                  onFavorite: () => onFavorite(product),
                  onTap: () => onOpenProduct(product),
                );
              },
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .72,
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
  });

  final ImpactSnapshot impact;
  final List<WasteRecord> wasteRecords;
  final List<EcoScoreEntry> scoreHistory;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final recycledItems = wasteRecords.fold<int>(
      0,
      (sum, record) => sum + record.recycledItems,
    );
    final foodSaved = wasteRecords.fold<double>(
      0,
      (sum, record) => sum + record.foodSavedKg,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const _TopBar(title: 'Waste Tracker'),
        const SizedBox(height: 16),
        _EcoScoreCard(score: impact.ecoScore),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Waste reduced',
                value: '${impact.totalWasteReduced} kg',
                icon: Icons.recycling,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Recycled items',
                value: '$recycledItems',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Food saved',
          value: '${foodSaved.toStringAsFixed(1)} kg',
          icon: Icons.restaurant_outlined,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAddRecord,
          icon: const Icon(Icons.add),
          label: const Text('Add waste record'),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Monthly statistics'),
        const SizedBox(height: 12),
        _MiniBarChart(values: impact.weeklyProgress),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Recent records'),
        const SizedBox(height: 12),
        if (wasteRecords.isEmpty)
          const _EmptyState(message: 'No waste records yet.')
        else
          ...wasteRecords.take(8).map(_WasteRecordTile.new),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Eco Score history & ranking'),
        const SizedBox(height: 12),
        if (scoreHistory.isEmpty)
          const _EmptyState(message: 'Eco Score history will appear here.')
        else
          ...scoreHistory.map(_ScoreHistoryTile.new),
      ],
    );
  }
}

class _MarketplaceTab extends StatelessWidget {
  const _MarketplaceTab({
    required this.products,
    required this.brands,
    required this.onOpenProduct,
  });

  final List<EcoProduct> products;
  final List<EcoBrand> brands;
  final ValueChanged<EcoProduct> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const _TopBar(title: 'Marketplace'),
        const SizedBox(height: 16),
        const _MarketplaceHero(),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Verified brands'),
        const SizedBox(height: 12),
        ...brands.map(_BrandRow.new),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Best sellers'),
        const SizedBox(height: 12),
        ...products.take(5).map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WideProductCard(
                  product: product,
                  onTap: () => onOpenProduct(product),
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
    required this.impact,
    required this.savedProducts,
    required this.avatarLoading,
    required this.onPickAvatar,
    required this.onDeleteAvatar,
    required this.onOpenSavedProducts,
    required this.onOpenOrderSettings,
    required this.onOpenHelpCenter,
    required this.onOpenProduct,
    required this.onSignOut,
  });

  final UserProfile profile;
  final ImpactSnapshot impact;
  final List<EcoProduct> savedProducts;
  final bool avatarLoading;
  final VoidCallback onPickAvatar;
  final VoidCallback onDeleteAvatar;
  final VoidCallback onOpenSavedProducts;
  final VoidCallback onOpenOrderSettings;
  final VoidCallback onOpenHelpCenter;
  final ValueChanged<EcoProduct> onOpenProduct;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const _TopBar(title: 'Profile'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _ProfileAvatar(profile: profile, loading: avatarLoading),
                  IconButton.filled(
                    onPressed: avatarLoading ? null : onPickAvatar,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.fullName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(profile.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: avatarLoading ? null : onPickAvatar,
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Upload photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: avatarLoading || profile.avatarUrl == null
                        ? null
                        : onDeleteAvatar,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete photo'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _EcoScoreCard(score: impact.ecoScore),
        const SizedBox(height: 18),
        _SectionHeader(
          title: 'Saved Products',
          action: 'View all',
          onAction: onOpenSavedProducts,
        ),
        const SizedBox(height: 12),
        if (savedProducts.isEmpty)
          const _EmptyState(message: 'Save products to see them here.')
        else
          ...savedProducts.take(3).map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WideProductCard(
                    product: product,
                    onTap: () => onOpenProduct(product),
                  ),
                ),
              ),
        const SizedBox(height: 8),
        _ProfileAction(
          icon: Icons.favorite_border,
          label: 'Saved Products',
          onTap: onOpenSavedProducts,
        ),
        _ProfileAction(
          icon: Icons.receipt_long_outlined,
          label: 'Order Settings',
          onTap: onOpenOrderSettings,
        ),
        _ProfileAction(
          icon: Icons.settings_outlined,
          label: 'Preferences',
          onTap: onOpenOrderSettings,
        ),
        _ProfileAction(
          icon: Icons.help_outline,
          label: 'Help Center',
          onTap: onOpenHelpCenter,
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

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({
    super.key,
    required this.repository,
    required this.onOpenProduct,
  });

  final EcoRepository repository;
  final ValueChanged<EcoProduct> onOpenProduct;

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  List<EcoProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await widget.repository.fetchSavedProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _unsave(EcoProduct product) async {
    await widget.repository.setFavorite(productId: product.id, favorite: false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Products')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const _EmptyState(message: 'No saved products yet.')
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return _WideProductCard(
                      product: product,
                      onTap: () => widget.onOpenProduct(product),
                      trailing: IconButton(
                        onPressed: () => _unsave(product),
                        icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      ),
                    );
                  },
                ),
    );
  }
}

class OrderSettingsScreen extends StatefulWidget {
  const OrderSettingsScreen({super.key, required this.repository});

  final EcoRepository repository;

  @override
  State<OrderSettingsScreen> createState() => _OrderSettingsScreenState();
}

class _OrderSettingsScreenState extends State<OrderSettingsScreen> {
  final _notesController = TextEditingController();
  OrderSettings _settings = OrderSettings.defaults();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await widget.repository.fetchOrderSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _notesController.text = settings.deliveryNotes;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      _settings = await widget.repository.updateOrderSettings(
        OrderSettings(
          plasticFreePackaging: _settings.plasticFreePackaging,
          contactlessDelivery: _settings.contactlessDelivery,
          refillReminders: _settings.refillReminders,
          preferredDeliveryWindow: _settings.preferredDeliveryWindow,
          deliveryNotes: _notesController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order settings saved.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SwitchListTile(
                  value: _settings.plasticFreePackaging,
                  title: const Text('Plastic-free packaging'),
                  subtitle: const Text('Prefer recyclable or compostable mailers.'),
                  onChanged: (value) => setState(
                    () => _settings = OrderSettings(
                      plasticFreePackaging: value,
                      contactlessDelivery: _settings.contactlessDelivery,
                      refillReminders: _settings.refillReminders,
                      preferredDeliveryWindow: _settings.preferredDeliveryWindow,
                      deliveryNotes: _settings.deliveryNotes,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: _settings.contactlessDelivery,
                  title: const Text('Contactless delivery'),
                  onChanged: (value) => setState(
                    () => _settings = OrderSettings(
                      plasticFreePackaging: _settings.plasticFreePackaging,
                      contactlessDelivery: value,
                      refillReminders: _settings.refillReminders,
                      preferredDeliveryWindow: _settings.preferredDeliveryWindow,
                      deliveryNotes: _settings.deliveryNotes,
                    ),
                  ),
                ),
                SwitchListTile(
                  value: _settings.refillReminders,
                  title: const Text('Refill reminders'),
                  subtitle: const Text('Notify me before recurring essentials run out.'),
                  onChanged: (value) => setState(
                    () => _settings = OrderSettings(
                      plasticFreePackaging: _settings.plasticFreePackaging,
                      contactlessDelivery: _settings.contactlessDelivery,
                      refillReminders: value,
                      preferredDeliveryWindow: _settings.preferredDeliveryWindow,
                      deliveryNotes: _settings.deliveryNotes,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _settings.preferredDeliveryWindow,
                  decoration: const InputDecoration(
                    labelText: 'Preferred delivery window',
                  ),
                  items: const ['Morning', 'Afternoon', 'Evening', 'Weekend']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(
                      () => _settings = OrderSettings(
                        plasticFreePackaging: _settings.plasticFreePackaging,
                        contactlessDelivery: _settings.contactlessDelivery,
                        refillReminders: _settings.refillReminders,
                        preferredDeliveryWindow: value,
                        deliveryNotes: _settings.deliveryNotes,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Delivery notes',
                    hintText: 'Gate code, pickup point, packaging notes...',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save settings'),
                ),
              ],
            ),
    );
  }
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key, required this.repository});

  final EcoRepository repository;

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a subject and issue details.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.repository.submitHelpIssue(subject: subject, body: body);
      _subjectController.clear();
      _bodyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted to support.')),
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
          _SupportCard(
            icon: Icons.phone_outlined,
            title: 'Contact Support',
            body: 'Call $_supportPhone for account, order, or tracker support.',
          ),
          const SizedBox(height: 12),
          const _SupportCard(
            icon: Icons.support_agent,
            title: 'Live support',
            body:
                'Live support is available every day from 9:00 AM to 10:00 PM. Urgent issues are prioritized.',
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'FAQ'),
          const SizedBox(height: 8),
          const ExpansionTile(
            title: Text('How are saved products stored?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Saved products are stored in Supabase and sync after logout/login.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How is my Eco Score calculated?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'The score updates automatically from food saved, recycled items, donations, and waste reduction records.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Can I change order preferences later?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Yes. Open Profile > Order Settings anytime.'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'Report Issue'),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Issue details',
              hintText: 'Tell us what happened...',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submitIssue,
            icon: const Icon(Icons.send_outlined),
            label: Text(_submitting ? 'Submitting...' : 'Submit issue'),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.repository});

  final EcoRepository repository;

  Future<void> _toggle(AppNotification notification) {
    return repository.setNotificationRead(
      notificationId: notification.id,
      read: !notification.isRead,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<AppNotification>>(
        stream: repository.watchNotifications(),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return const _EmptyState(message: 'No notifications yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: Icon(
                  notification.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(notification.title),
                subtitle: Text(notification.body),
                trailing: TextButton(
                  onPressed: () => _toggle(notification),
                  child: Text(notification.isRead ? 'Unread' : 'Read'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: onFavorite,
                  icon: Icon(
                    product.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: product.isFavorite ? Colors.redAccent : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProductVisual(product: product, height: 290),
            const SizedBox(height: 18),
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(product.brandName, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _money(product.price),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const Spacer(),
                _EcoBadge(score: product.ecoScore),
              ],
            ),
            const SizedBox(height: 18),
            Text(product.description),
            const SizedBox(height: 18),
            _InfoTile(
              icon: Icons.category_outlined,
              title: 'Material',
              subtitle: product.material,
            ),
            _InfoTile(
              icon: Icons.local_shipping_outlined,
              title: 'Shipping',
              subtitle: product.shippingNote,
            ),
            _InfoTile(
              icon: Icons.co2_outlined,
              title: 'Estimated impact',
              subtitle:
                  '${product.co2SavedKg.toStringAsFixed(1)}kg CO2 and ${product.waterSavedLiters}L water saved',
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Similar products'),
            const SizedBox(height: 12),
            ...similarProducts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WideProductCard(product: item, onTap: () {}),
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
    this.unreadCount = 0,
    this.onNotifications,
  });

  final String title;
  final int unreadCount;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: .16),
          child: Icon(Icons.eco, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        if (onNotifications != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.tip});

  final UserProfile profile;
  final EcoTip? tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4B7052),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${profile.fullName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tip?.body ?? 'Reduce waste, save products, and track impact daily.',
            style: const TextStyle(color: Color(0xFFE8F0E4), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.onFavorite,
  });

  final EcoProduct product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _ProductVisual(product: product)),
                  if (onFavorite != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: onFavorite,
                          icon: Icon(
                            product.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: product.isFavorite
                                ? Colors.redAccent
                                : Colors.grey[700],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              product.brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(_money(product.price)),
                const Spacer(),
                _EcoBadge(score: product.ecoScore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideProductCard extends StatelessWidget {
  const _WideProductCard({
    required this.product,
    required this.onTap,
    this.trailing,
  });

  final EcoProduct product;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(radius: 22),
        child: Row(
          children: [
            SizedBox(width: 70, height: 70, child: _ProductVisual(product: product)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(product.impactLabel, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(_money(product.price)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product, this.height});

  final EcoProduct product;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          product.imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(Icons.eco_outlined, color: color, size: height == null ? 42 : 78),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.loading});

  final UserProfile profile;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    return CircleAvatar(
      radius: 48,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .16),
      backgroundImage:
          avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      child: loading
          ? const CircularProgressIndicator()
          : avatarUrl == null || avatarUrl.isEmpty
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                )
              : null,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
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
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: (score / 100).clamp(0, 1),
                  strokeWidth: 8,
                  backgroundColor: color.withValues(alpha: .12),
                ),
              ),
              Text('$score', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eco Score', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                  'Automatically recalculated from recycling, donations, food saved, and waste reduction.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((value, element) => value > element ? value : element);
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FractionallySizedBox(
                    heightFactor: (value / maxValue).clamp(.08, 1).toDouble(),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WasteRecordTile extends StatelessWidget {
  const _WasteRecordTile(this.record);

  final WasteRecord record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: const Icon(Icons.recycling),
      title: Text(_recordTitle(record.type)),
      subtitle: Text(record.note.isEmpty ? 'Waste tracker record' : record.note),
      trailing: Text('${record.amountKg.toStringAsFixed(1)}kg'),
    );
  }
}

class _ScoreHistoryTile extends StatelessWidget {
  const _ScoreHistoryTile(this.entry);

  final EcoScoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: CircleAvatar(child: Text('${entry.score}')),
      title: Text(entry.reason),
      subtitle: Text(entry.rankLabel),
    );
  }
}

class _BrandSpotlight extends StatelessWidget {
  const _BrandSpotlight({required this.brand});

  final EcoBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, child: Icon(Icons.verified_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(brand.description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow(this.brand);

  final EcoBrand brand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
        title: Text(brand.name),
        subtitle: Text(brand.tagline),
        trailing: brand.verified
            ? const Icon(Icons.verified, color: Color(0xFF4B7052))
            : null,
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE6D7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop low-waste essentials',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text('Verified brands, saved favorites, and plastic-free order settings.'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.primary, size: 56),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Retry'))),
      ],
    );
  }
}

class _WasteRecordSheet extends StatefulWidget {
  const _WasteRecordSheet();

  @override
  State<_WasteRecordSheet> createState() => _WasteRecordSheetState();
}

class _WasteRecordSheetState extends State<_WasteRecordSheet> {
  final _amountController = TextEditingController(text: '1');
  final _recycledController = TextEditingController(text: '0');
  final _foodController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  String _type = 'waste_reduced';

  @override
  void dispose() {
    _amountController.dispose();
    _recycledController.dispose();
    _foodController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final recycled = int.tryParse(_recycledController.text.trim()) ?? 0;
    final food = double.tryParse(_foodController.text.trim()) ?? 0;
    if (amount <= 0 && recycled <= 0 && food <= 0) return;
    Navigator.of(context).pop(
      _WasteRecordDraft(
        type: _type,
        amountKg: amount,
        recycledItems: recycled,
        foodSavedKg: food,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add waste record',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Activity type'),
            items: const [
              DropdownMenuItem(value: 'waste_reduced', child: Text('Reduced waste')),
              DropdownMenuItem(value: 'recycle', child: Text('Recycled items')),
              DropdownMenuItem(value: 'food_saved', child: Text('Saved food')),
              DropdownMenuItem(value: 'donation', child: Text('Donated products')),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Waste reduced (kg)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recycledController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Recycled items'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _foodController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Food saved (kg)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Save record')),
          ),
        ],
      ),
    );
  }
}

class _WasteRecordDraft {
  const _WasteRecordDraft({
    required this.type,
    required this.amountKg,
    required this.recycledItems,
    required this.foodSavedKg,
    required this.note,
  });

  final String type;
  final double amountKg;
  final int recycledItems;
  final double foodSavedKg;
  final String note;
}

extension on ImpactSnapshot {
  int get totalWasteReduced {
    return plasticWasteReduction + foodWasteReduction + packagingReduction;
  }
}

BoxDecoration _cardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .05),
        blurRadius: 24,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _contentTypeFor(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

String? _validateImage(int byteLength, String contentType) {
  const maxBytes = 5 * 1024 * 1024;
  if (byteLength == 0) return 'Selected image is empty.';
  if (byteLength > maxBytes) return 'Profile photo must be 5MB or smaller.';
  if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(contentType)) {
    return 'Use a JPG, PNG, or WEBP image.';
  }
  return null;
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
