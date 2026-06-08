import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/marketplace_repository.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final MarketplaceRepository repository;
  final AuthService authService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    _OnboardingSlide(
      eyebrow: 'Curated drops',
      title: 'Discover rare digital art before it trends',
      description:
          'Explore verified collections, featured auctions, and live floor prices from one cinematic marketplace.',
      icon: Icons.auto_awesome,
      accent: Color(0xFF8B5CF6),
    ),
    _OnboardingSlide(
      eyebrow: 'Bid smarter',
      title: 'Track bids, rarity, and chain data at a glance',
      description:
          'Review current ask, highest bid, sale history, token traits, and timed auctions before you collect.',
      icon: Icons.bolt,
      accent: Color(0xFF22D3EE),
    ),
    _OnboardingSlide(
      eyebrow: 'Your portfolio',
      title: 'Build a watchlist that follows your wallet',
      description:
          'Save favorite NFTs, monitor portfolio value, and connect Supabase auth for a production-ready account layer.',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFFFF7A59),
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const _BrandMark(size: 42),
                  const SizedBox(width: 12),
                  Text(
                    'NovaNFT',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _openLogin, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 18),
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
                    width: index == _page ? 34 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? _slides[index].accent
                          : Colors.white.withValues(alpha: .16),
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
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _page == _slides.length - 1
                        ? 'Enter marketplace'
                        : 'Continue',
                  ),
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
    return Column(
      children: [
        Expanded(
          child: Center(
            child: _OnboardingArtwork(slide: slide),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          slide.eyebrow.toUpperCase(),
          style: TextStyle(
            color: slide.accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFA5ABC0),
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _OnboardingArtwork extends StatelessWidget {
  const _OnboardingArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 390),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            slide.accent.withValues(alpha: .95),
            const Color(0xFF1D2030),
            const Color(0xFF0E1019),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: .28),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: _GlowOrb(color: Colors.white.withValues(alpha: .18)),
          ),
          Positioned(
            left: 26,
            top: 26,
            child: _GlassPill(icon: slide.icon, label: 'Live auction'),
          ),
          const Positioned(
            right: 24,
            bottom: 28,
            child: _BidCard(),
          ),
          Center(
            child: Transform.rotate(
              angle: -.08,
              child: _NftPreviewCard(accent: slide.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _NftPreviewCard extends StatelessWidget {
  const _NftPreviewCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 248,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171927),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: .95),
                    accent,
                    const Color(0xFF0E1019),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.blur_on, color: Colors.white, size: 70),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ape Nebula #214',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '4.82 ETH',
            style: TextStyle(color: accent, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Highest bid', style: TextStyle(color: Color(0xFFC8CDDD))),
          SizedBox(height: 4),
          Text(
            '4.55 ETH',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .32),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
        ),
      ),
      child: const Icon(Icons.diamond_outlined, color: Colors.white),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
