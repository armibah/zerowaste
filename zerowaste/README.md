# EcoDiscover

EcoDiscover is a Flutter + Supabase starter app for discovering sustainable
brands, zero-waste products, and practical low-waste tips.

## What is included

- Flutter Material 3 onboarding, login/sign-up, and discovery dashboard.
- Multi-tab mobile UI matching the provided EcoDiscover mockups:
  - Join the Movement sign-up
  - Home dashboard
  - Product marketplace grid
  - Product detail page
  - Impact tracker
  - Profile
- Supabase Auth integration for email/password accounts.
- Supabase Postgres integration for brands, products, tips, and user favorites.
- Supabase impact tracker table with a trigger that creates default user stats.
- Demo mode that works without Supabase keys for local UI development.
- Database schema and seed data in [`supabase/schema.sql`](supabase/schema.sql).

## Run the app

Install dependencies:

```bash
flutter pub get
```

Run without Supabase keys to use demo data:

```bash
flutter run
```

Run with Supabase:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Supabase setup

1. Create a Supabase project.
2. Open the SQL editor.
3. Run the contents of `supabase/schema.sql`.
4. In Authentication > Providers, enable Email.
5. Start Flutter with the `SUPABASE_URL` and `SUPABASE_ANON_KEY` dart defines.

The schema creates these tables:

- `eco_brands`
- `eco_products`
- `eco_tips`
- `user_favorites`
- `impact_snapshots`

Row level security is enabled. Brands, products, and tips are readable by
anonymous and authenticated users. Favorites and impact snapshots are private to
the signed-in user.

## Main Flutter files

- `lib/main.dart` initializes Supabase and switches between live/demo services.
- `lib/screens/login_screen.dart` contains the sign-up and login UI.
- `lib/screens/home_screen.dart` contains the home, product, tracker,
  marketplace, profile, and product detail designs.
- `lib/services/eco_repository.dart` contains Supabase queries and demo data.

## Tests and checks

```bash
flutter analyze
flutter test
```
