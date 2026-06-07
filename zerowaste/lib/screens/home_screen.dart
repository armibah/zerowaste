import 'package:flutter/material.dart';

import '../models/eco_brand.dart';
import '../models/eco_product.dart';
import '../models/eco_tip.dart';
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
  String _category = 'All';
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

      if (!mounted) return;
      setState(() {
        _products = products;
        _brands = brands;
        _tips = tips;
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
            (item) =>
                item.id == product.id ? item.copyWith(isFavorite: nextFavorite) : item,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: .14),
                            child: Icon(Icons.eco, color: colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EcoDiscover',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  widget.authService.currentEmail ??
                                      'Find your next low-waste swap',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _signOut,
                            tooltip: 'Sign out',
                            icon: const Icon(Icons.logout_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Discover sustainable swaps',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF20251F),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plastic-free products, verified brands, and habits for a lighter footprint.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF647061),
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search bamboo, refill, cotton...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: _error!, onRetry: _load),
                )
              else ...[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category == _category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) => setState(() => _category = category),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Recommended products',
                    actionLabel: '${_filteredProducts.length} found',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _filteredProducts[index];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          index == 0 ? 0 : 12,
                          20,
                          0,
                        ),
                        child: _ProductCard(
                          product: product,
                          onFavorite: () => _toggleFavorite(product),
                        ),
                      );
                    },
                    childCount: _filteredProducts.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Verified brands',
                    actionLabel: '${_brands.length} partners',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 170,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _brands.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _BrandCard(brand: _brands[index]);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Zero-waste tips',
                    actionLabel: 'Today',
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          index == 0 ? 0 : 10,
                          20,
                          index == _tips.length - 1 ? 28 : 0,
                        ),
                        child: _TipCard(tip: _tips[index]),
                      );
                    },
                    childCount: _tips.length,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF20251F),
                ),
          ),
          const Spacer(),
          Text(
            actionLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onFavorite});

  final EcoProduct product;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .045),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 82,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              _categoryIcon(product.category),
              color: colorScheme.primary,
              size: 42,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: onFavorite,
                      icon: Icon(
                        product.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: product.isFavorite
                            ? const Color(0xFFD86B64)
                            : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  product.brandName,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], height: 1.3),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: product.impactLabel, filled: true),
                    ...product.tags.take(2).map((tag) => _Pill(label: tag)),
                  ],
                ),
              ],
            ),
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: .2),
                child: const Icon(Icons.storefront_outlined, color: Colors.white),
              ),
              const Spacer(),
              if (brand.verified)
                const Icon(Icons.verified, color: Color(0xFFD6E6B9)),
            ],
          ),
          const Spacer(),
          Text(
            brand.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
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

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final EcoTip tip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: .12),
            child: Icon(_tipIcon(tip.iconName), color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: TextStyle(color: Colors.grey[700], height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? colorScheme.primary.withValues(alpha: .12)
            : const Color(0xFFF3F4F1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? colorScheme.primary : const Color(0xFF647061),
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 54),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Cleaning' => Icons.cleaning_services_outlined,
    'Grocery' => Icons.shopping_basket_outlined,
    'Kitchen' => Icons.kitchen_outlined,
    'Personal Care' => Icons.spa_outlined,
    _ => Icons.eco_outlined,
  };
}

IconData _tipIcon(String iconName) {
  return switch (iconName) {
    'jar' => Icons.inventory_2_outlined,
    'leaf' => Icons.eco_outlined,
    'repair' => Icons.handyman_outlined,
    _ => Icons.lightbulb_outline,
  };
}
