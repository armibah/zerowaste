import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/marketplace_repository.dart';

class NftMarketApp extends StatelessWidget {
  const NftMarketApp({
    super.key,
    required this.repository,
    required this.authService,
  });

  final MarketplaceRepository repository;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8B5CF6);
    const background = Color(0xFF0A0B12);

    return MaterialApp(
      title: 'NovaNFT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          primary: seed,
          secondary: const Color(0xFF22D3EE),
          surface: const Color(0xFF151724),
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF11131E),
          indicatorColor: seed.withValues(alpha: .22),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF8B90A5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171927),
          hintStyle: const TextStyle(color: Color(0xFF777D95)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF262A3B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF262A3B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: seed, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      home: OnboardingScreen(repository: repository, authService: authService),
    );
  }
}
