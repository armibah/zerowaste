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
