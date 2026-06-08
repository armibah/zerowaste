import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/eco_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: 'https://donuunbpmzrohgtwquzi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvbnV1bmJwbXpyb2hndHdxdXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4MjQxNzcsImV4cCI6MjA5NjQwMDE3N30.vCvt0SZ2V4rZmYZ_jSj0Kq7kW1CbvT3yY0KyyLVIUS4',
    );
  }

  runApp(
    EcoDiscoverApp(
      repository: DemoEcoRepository(),
      authService: DemoAuthService(),
    ),
  );
}
