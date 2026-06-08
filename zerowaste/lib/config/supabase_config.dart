const String supabaseUrl = 'https://your-project-ref.supabase.co';
const String supabaseAnonKey = 'your-anon-key-here';

bool get isSupabaseConfigured {
  return supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project-ref') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('your-anon-key');
}
