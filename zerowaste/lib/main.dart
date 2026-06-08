import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/marketplace_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SupabaseClient? client;
  if (isSupabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    client = Supabase.instance.client;
  }

  runApp(
    NftMarketApp(
      repository: client == null
          ? DemoMarketplaceRepository()
          : SupabaseMarketplaceRepository(client),
      authService: client == null ? DemoAuthService() : SupabaseAuthService(client),
    ),
  );
}
