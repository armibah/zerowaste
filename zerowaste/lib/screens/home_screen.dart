import 'package:flutter/material.dart';

import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';
import '../models/impact_snapshot.dart';
import '../services/auth_service.dart';
import '../services/eco_repository.dart';
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
  List<EcoBrand> _brands = [];
  List<EcoTip> _tips = [];
  ImpactSnapshot? _impact;
  String _category = 'All';
  int _tab = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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

      if (!mounted) return;
      setState(() {
        _products = products;
        _brands = brands;
        _tips = tips;
        _impact = impact;
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

  @override
  Widget build(BuildContext context) {
    final impact = _impact;

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
                          brands: _brands,
                          tips: _tips,
                          impact: impact,
                          onOpenProducts: () => setState(() => _tab = 1),
                          onOpenProduct: _openProduct,
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
                        ),
                        _TrackerTab(impact: impact),
                        _MarketplaceTab(
                          products: _products,
                          brands: _brands,
                          onOpenProduct: _openProduct,
                        ),
                        _ProfileTab(
                          email: widget.authService.currentEmail,
                          impact: impact,
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
    required this.brands,
    required this.tips,
    required this.impact,
    required this.onOpenProducts,
    required this.onOpenProduct,
    required this.onSignOut,
  });

  final List<EcoProduct> products;
  final List<EcoBrand> brands;
  final List<EcoTip> tips;
  final ImpactSnapshot impact;
  final VoidCallback onOpenProducts;
  final ValueChanged<EcoProduct> onOpenProduct;
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
                _TopBar(title: 'EcoDiscover', onSignOut: onSignOut),
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
                const _TopBar(title: 'EcoDiscover'),
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
  const _TrackerTab({required this.impact});

  final ImpactSnapshot impact;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _TopBar(title: 'EcoDiscover'),
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
                const SizedBox(height: 22),
                _ActivityList(activities: impact.activities),
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
  });

  final List<EcoProduct> products;
  final List<EcoBrand> brands;
  final ValueChanged<EcoProduct> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: _TopBar(title: 'Marketplace'),
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
    required this.email,
    required this.impact,
    required this.onSignOut,
  });

  final String? email;
  final ImpactSnapshot impact;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        const _TopBar(title: 'Profile'),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 42,
          backgroundColor: color.withValues(alpha: .14),
          child: Icon(Icons.eco, color: color, size: 42),
        ),
        const SizedBox(height: 14),
        Text(
          'Eco Hero',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          email ?? 'nature@example.com',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 18),
        _EcoScoreCard(score: impact.ecoScore),
        const SizedBox(height: 14),
        _ProfileAction(icon: Icons.favorite_border, label: 'Saved Products'),
        _ProfileAction(icon: Icons.receipt_long_outlined, label: 'Orders'),
        _ProfileAction(icon: Icons.settings_outlined, label: 'Settings'),
        _ProfileAction(icon: Icons.help_outline, label: 'Help Center'),
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
  const _TopBar({required this.title, this.onSignOut});

  final String title;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.notifications_none),
          visualDensity: VisualDensity.compact,
        ),
      ],
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
  const _ProfileAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Icon(Icons.chevron_right),
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
    _ => Icons.eco_outlined,
  };
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}
