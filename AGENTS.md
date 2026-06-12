# AGENTS.md

## Cursor Cloud specific instructions

This repo is a single Flutter app located in the `zerowaste/` subdirectory (not the repo root). Run all Flutter commands from `zerowaste/`.

- App: `EcoDiscover`, a zero-waste product discovery UI. It runs fully offline using in-memory demo data (`DemoEcoRepository` / `DemoAuthService`), so no Supabase backend or secrets are required to run, test, or demo it. `Supabase.initialize` is intentionally skipped because `lib/config/supabase_config.dart` still holds placeholder values (`isSupabaseConfigured` returns `false`).
- Flutter SDK 3.44.2 (Dart 3.12.2) is installed at `/opt/flutter` and added to `PATH` via `~/.bashrc`. If `flutter` is not found in a fresh shell, run `export PATH="$PATH:/opt/flutter/bin"`.
- Standard commands (run from `zerowaste/`):
  - Install deps: `flutter pub get`
  - Lint/analyze: `flutter analyze` (a few `info`-level lints remain; there are no errors)
  - Tests: `flutter test`
  - Run on web: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` then open `http://localhost:8080` in Chrome. Linux desktop (`-d linux`) and Chrome (`-d chrome`) devices are also available.
- The login screen is pre-filled with demo credentials (`nature@example.com` / `ecodiscover`); pressing the submit button navigates straight to the home screen via the demo auth service.
