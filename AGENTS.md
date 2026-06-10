# AGENTS.md

## Cursor Cloud specific instructions

### Product

Single Flutter app **EcoDiscover** in `zerowaste/`. Demo mode is the default (`DemoEcoRepository` + `DemoAuthService` in `lib/main.dart`); no Supabase or other backend is required for local development.

### Flutter SDK

Flutter stable is installed at `~/flutter` with web enabled. Ensure it is on `PATH`:

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

`flutter doctor` should show Chrome as available. Android SDK and Linux desktop GTK tooling are optional and not required for web development.

### Common commands

Run from `zerowaste/`:

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint / analyze | `flutter analyze` |
| Tests | `flutter test` |
| Dev server (web) | `flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0` |
| Dev server (Chrome) | `flutter run -d chrome` |
| Release build | `flutter build web` |

### Demo login flow

1. Open the app (onboarding → login).
2. Demo credentials are pre-filled on the login screen (`nature@example.com`); any email/password works in demo mode.
3. Home screen shows products, tips, impact stats, and navigation tabs.

### Notes

- `flutter analyze` may report info-level lints (e.g. deprecated `anonKey` in `main.dart`); these do not block builds.
- `test/widget_test.dart` may be out of date with onboarding copy; verify against `lib/screens/onboarding_screen.dart` if tests fail.
- For live Supabase mode, set keys in `lib/config/supabase_config.dart` and swap in `SupabaseEcoRepository` / `SupabaseAuthService` in `main.dart`.
