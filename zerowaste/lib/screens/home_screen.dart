import 'package:flutter/material.dart';

import '../models/market_activity.dart';
import '../models/nft_collection.dart';
import '../models/nft_listing.dart';
import '../models/portfolio_snapshot.dart';
import '../services/auth_service.dart';
import '../services/marketplace_repository.dart';
import 'login_screen.dart';

const _bg = Color(0xFF0A0B12);
const _surface = Color(0xFF121420);
const _surfaceHigh = Color(0xFF191C2B);
const _muted = Color(0xFFA5ABC0);
const _line = Color(0xFF252A3D);
const _primary = Color(0xFF8B5CF6);
const _cyan = Color(0xFF22D3EE);
const _orange = Color(0xFFFF7A59);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final MarketplaceRepository repository;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  List<NftListing> _listings = [];
  List<NftCollection> _collections = [];
  List<MarketActivity> _activities = [];
  PortfolioSnapshot? _portfolio;
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
      final listings = await widget.repository.fetchListings();
      final collections = await widget.repository.fetchCollections();
      final activities = await widget.repository.fetchActivities();
      final portfolio = await widget.repository.fetchPortfolioSnapshot();

      if (!mounted) return;
      setState(() {
        _listings = listings;
        _collections = collections;
        _activities = activities;
        _portfolio = portfolio;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the marketplace.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(NftListing listing) async {
    final nextFavorite = !listing.isFavorite;

    setState(() {
      _listings = _listings
          .map(
            (item) => item.id == listing.id
                ? item.copyWith(isFavorite: nextFavorite)
                : item,
          )
          .toList();
    });

    try {
      await widget.repository.setFavorite(
        listingId: listing.id,
        favorite: nextFavorite,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listings = _listings
            .map(
              (item) => item.id == listing.id
                  ? item.copyWith(isFavorite: listing.isFavorite)
                  : item,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update watchlist.')),
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
    final values = _listings.map((listing) => listing.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<NftListing> get _filteredListings {
    final query = _searchController.text.trim().toLowerCase();

    return _listings.where((listing) {
      final matchesCategory =
          _category == 'All' || listing.category == _category;
      final matchesSearch = query.isEmpty ||
          listing.title.toLowerCase().contains(query) ||
          listing.collectionName.toLowerCase().contains(query) ||
          listing.creator.toLowerCase().contains(query) ||
          listing.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openListing(NftListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NftDetailScreen(
          listing: listing,
          similarListings: _listings
              .where((item) => item.id != listing.id)
              .take(3)
              .toList(),
          onFavorite: () => _toggleFavorite(listing),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = _portfolio;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null || portfolio == null
                  ? _ErrorState(
                      message: _error ?? 'Missing portfolio data',
                      onRetry: _load,
                    )
                  : IndexedStack(
                      index: _tab,
                      children: [
                        _DiscoverTab(
                          listings: _listings,
                          collections: _collections,
                          activities: _activities,
                          portfolio: portfolio,
                          isDemo: widget.authService.isDemo,
                          onOpenExplore: () => setState(() => _tab = 1),
                          onOpenListing: _openListing,
                          onSignOut: _signOut,
                        ),
                        _ExploreTab(
                          listings: _filteredListings,
                          searchController: _searchController,
                          categories: _categories,
                          selectedCategory: _category,
                          onSearchChanged: (_) => setState(() {}),
                          onCategoryChanged: (value) =>
                              setState(() => _category = value),
                          onFavorite: _toggleFavorite,
                          onOpenListing: _openListing,
                        ),
                        _DropsTab(
                          collections: _collections,
                          activities: _activities,
                        ),
                        _PortfolioTab(
                          email: widget.authService.currentEmail,
                          listings: _listings,
                          portfolio: portfolio,
                          onOpenListing: _openListing,
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
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department),
            label: 'Drops',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
        ],
      ),
    );
  }
}

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({
    required this.listings,
    required this.collections,
    required this.activities,
    required this.portfolio,
    required this.isDemo,
    required this.onOpenExplore,
    required this.onOpenListing,
    required this.onSignOut,
  });

  final List<NftListing> listings;
  final List<NftCollection> collections;
  final List<MarketActivity> activities;
  final PortfolioSnapshot portfolio;
  final bool isDemo;
  final VoidCallback onOpenExplore;
  final ValueChanged<NftListing> onOpenListing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final featured = listings.isEmpty ? null : listings.first;
    final trending = listings.skip(1).take(4).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(title: 'NovaNFT', onSignOut: onSignOut),
                const SizedBox(height: 16),
                if (isDemo) ...[
                  const _SupabaseBanner(),
                  const SizedBox(height: 16),
                ],
                if (featured != null)
                  _FeaturedHero(
                    listing: featured,
                    onOpen: () => onOpenListing(featured),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Portfolio',
                        value: '${portfolio.portfolioValueEth.toStringAsFixed(2)} ETH',
                        icon: Icons.account_balance_wallet_outlined,
                        accent: _primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Watchlist',
                        value: '${portfolio.watchlistCount} NFTs',
                        icon: Icons.favorite_border,
                        accent: _cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Trending auctions',
                  action: 'Explore all',
                  onAction: onOpenExplore,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final listing = trending[index];
                return _ListingCard(
                  listing: listing,
                  onTap: () => onOpenListing(listing),
                );
              },
              childCount: trending.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .72,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Verified collections'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 176,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: collections.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _CollectionCard(collection: collections[index]);
                    },
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionHeader(title: 'Live market activity'),
                const SizedBox(height: 12),
                ...activities.map(_ActivityTile.new),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({
    required this.listings,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onFavorite,
    required this.onOpenListing,
  });

  final List<NftListing> listings;
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<NftListing> onFavorite;
  final ValueChanged<NftListing> onOpenListing;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TopBar(title: 'Explore NFTs'),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search collection, creator, token...',
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
                        selectedColor: _primary.withValues(alpha: .28),
                        side: const BorderSide(color: _line),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${listings.length} live listings',
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final listing = listings[index];
                return _ListingCard(
                  listing: listing,
                  onFavorite: () => onFavorite(listing),
                  onTap: () => onOpenListing(listing),
                );
              },
              childCount: listings.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .70,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropsTab extends StatelessWidget {
  const _DropsTab({required this.collections, required this.activities});

  final List<NftCollection> collections;
  final List<MarketActivity> activities;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        const _TopBar(title: 'Drops'),
        const SizedBox(height: 16),
        const _DropHero(),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Collection floor'),
        const SizedBox(height: 12),
        ...collections.map(
          (collection) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CollectionRow(collection: collection),
          ),
        ),
        const SizedBox(height: 10),
        const _SectionHeader(title: 'Latest activity'),
        const SizedBox(height: 12),
        ...activities.map(_ActivityTile.new),
      ],
    );
  }
}

class _PortfolioTab extends StatelessWidget {
  const _PortfolioTab({
    required this.email,
    required this.listings,
    required this.portfolio,
    required this.onOpenListing,
    required this.onSignOut,
  });

  final String? email;
  final List<NftListing> listings;
  final PortfolioSnapshot portfolio;
  final ValueChanged<NftListing> onOpenListing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final watched = listings.where((listing) => listing.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _TopBar(title: 'Portfolio', onSignOut: onSignOut),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: _primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nova Collector',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          email ?? 'Demo wallet',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Balance',
                      value: '${portfolio.balanceEth.toStringAsFixed(2)} ETH',
                      icon: Icons.currency_bitcoin,
                      accent: _orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Created',
                      value: '${portfolio.createdCount}',
                      icon: Icons.brush_outlined,
                      accent: _cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MiniTrendChart(values: portfolio.trendingScores),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Watchlist'),
        const SizedBox(height: 12),
        if (watched.isEmpty)
          const _EmptyWatchlist()
        else
          ...watched.map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WideListingCard(
                listing: listing,
                onTap: () => onOpenListing(listing),
              ),
            ),
          ),
      ],
    );
  }
}

class NftDetailScreen extends StatelessWidget {
  const NftDetailScreen({
    super.key,
    required this.listing,
    required this.similarListings,
    required this.onFavorite,
  });

  final NftListing listing;
  final List<NftListing> similarListings;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final accent = Color(listing.accentColor);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            listing.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: listing.isFavorite ? Colors.redAccent : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Hero(
                      tag: 'nft-${listing.id}',
                      child: _NftArtwork(listing: listing, height: 360),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _Pill(
                          label: listing.collectionName,
                          icon: Icons.verified,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          label: listing.chain,
                          icon: Icons.hub_outlined,
                          color: _cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created by ${listing.creator} - Token ${listing.tokenId}',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _panelDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current ask', style: TextStyle(color: _muted)),
                          const SizedBox(height: 6),
                          Text(
                            _eth(listing.priceEth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _showAction(
                                    context,
                                    'Bid flow ready for Supabase functions.',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Place bid'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _showAction(
                                    context,
                                    'Checkout can be wired to wallet payments.',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: _line),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Buy now'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailMetric(
                            label: 'Highest bid',
                            value: _eth(listing.highestBidEth),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Last sale',
                            value: _eth(listing.lastSaleEth),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailMetric(
                            label: 'Rarity',
                            value: listing.rarity,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.description,
                      style: const TextStyle(color: _muted, height: 1.55),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.tags
                          .map((tag) => _Pill(label: tag, color: accent))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: 'More like this'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = similarListings[index];
                    return _ListingCard(listing: item);
                  },
                  childCount: similarListings.length,
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
        ),
      ),
    );
  }

  void _showAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [_primary, _cyan]),
          ),
          child: const Icon(Icons.diamond_outlined, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSignOut,
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

class _SupabaseBanner extends StatelessWidget {
  const _SupabaseBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withValues(alpha: .32)),
      ),
      child: const Row(
        children: [
          Icon(Icons.storage_outlined, color: Color(0xFFD9D6FF)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo data is showing. Configure Supabase keys for live collections, listings, and watchlists.',
              style: TextStyle(color: Color(0xFFD9D6FF), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({required this.listing, required this.onOpen});

  final NftListing listing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = Color(listing.accentColor);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(34),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, const Color(0xFF1B1D2C), _surface],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .30),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _GlassChip(label: 'Featured auction'),
                const Spacer(),
                _GlassChip(label: listing.endsIn),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.collectionName,
                        style: const TextStyle(color: Color(0xFFE5E7FF)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _eth(listing.priceEth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _bg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('View NFT'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  height: 178,
                  child: Hero(
                    tag: 'nft-${listing.id}',
                    child: _NftArtwork(listing: listing),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropHero extends StatelessWidget {
  const _DropHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_orange, _primary, Color(0xFF151724)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassChip(label: 'Mint window opens soon'),
          SizedBox(height: 34),
          Text(
            'Neon Samurai season two',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Early access list, reserve pricing, and reveal mechanics are ready for Supabase edge functions.',
            style: TextStyle(color: Color(0xFFE8EAFF), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    this.onTap,
    this.onFavorite,
  });

  final NftListing listing;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: _panelDecoration(radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _NftArtwork(listing: listing)),
                  if (onFavorite != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _RoundIconButton(
                        icon: listing.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: listing.isFavorite ? Colors.redAccent : Colors.white,
                        onTap: onFavorite!,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              listing.collectionName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _eth(listing.priceEth),
                  style: TextStyle(
                    color: Color(listing.accentColor),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  listing.endsIn,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideListingCard extends StatelessWidget {
  const _WideListingCard({required this.listing, required this.onTap});

  final NftListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(radius: 24),
        child: Row(
          children: [
            SizedBox(width: 82, height: 82, child: _NftArtwork(listing: listing)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.collectionName,
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _eth(listing.priceEth),
                    style: TextStyle(
                      color: Color(listing.accentColor),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _NftArtwork extends StatelessWidget {
  const _NftArtwork({required this.listing, this.height});

  final NftListing listing;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final accent = Color(listing.accentColor);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: const Alignment(-.45, -.55),
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: .95),
            accent,
            Color.lerp(accent, _bg, .72) ?? _bg,
            const Color(0xFF090A10),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 16,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: .55),
              size: 34,
            ),
          ),
          Center(
            child: Icon(
              _artIcon(listing.category),
              color: Colors.white.withValues(alpha: .92),
              size: height == null ? 58 : 112,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: _GlassChip(label: listing.rarity),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final NftCollection collection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Color(collection.accentColor), _surfaceHigh],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.blur_circular,
                color: Colors.white.withValues(alpha: .9),
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (collection.verified)
                const Icon(Icons.verified, color: _cyan, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(collection.creator, style: const TextStyle(color: _muted)),
          const Spacer(),
          Text(
            'Floor ${_eth(collection.floorPriceEth)}',
            style: TextStyle(
              color: Color(collection.accentColor),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.collection});

  final NftCollection collection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(collection.accentColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.diamond_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        collection.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (collection.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: _cyan, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${collection.items} items - ${collection.category}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _eth(collection.floorPriceEth),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${collection.volumeEth.toStringAsFixed(0)} ETH vol',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.activity);

  final MarketActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(radius: 22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_activityIcon(activity.iconName), color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(activity.subtitle, style: const TextStyle(color: _muted)),
              ],
            ),
          ),
          Text(
            _eth(activity.valueEth),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: _muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((value, element) => value > element ? value : element);

    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FractionallySizedBox(
                    heightFactor: (value / maxValue).clamp(.12, 1).toDouble(),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [_primary, _cyan],
                        ),
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

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _panelDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: .28),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration(radius: 26),
      child: const Column(
        children: [
          Icon(Icons.favorite_border, color: _primary, size: 42),
          SizedBox(height: 12),
          Text(
            'Your watchlist is empty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Tap the heart on listings to track auctions here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.cloud_off_outlined, color: _primary, size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Retry'))),
      ],
    );
  }
}

BoxDecoration _panelDecoration({double radius = 28}) {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _line),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .18),
        blurRadius: 18,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

String _eth(double value) => '${value.toStringAsFixed(2)} ETH';

IconData _artIcon(String category) {
  switch (category.toLowerCase()) {
    case 'gaming':
      return Icons.sports_esports_outlined;
    case 'pfp':
      return Icons.face_retouching_natural;
    default:
      return Icons.blur_on;
  }
}

IconData _activityIcon(String name) {
  switch (name) {
    case 'bolt':
      return Icons.bolt;
    case 'verified':
      return Icons.verified;
    default:
      return Icons.sell_outlined;
  }
}
