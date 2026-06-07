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
