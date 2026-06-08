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