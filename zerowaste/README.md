# EcoDiscover

EcoDiscover is a Flutter + Supabase starter app for discovering sustainable
brands, zero-waste products, and practical low-waste tips.

## What is included

- Flutter Material 3 onboarding, login/sign-up, and discovery dashboard.
- Supabase Auth integration for email/password accounts.
- Supabase Postgres integration for brands, products, tips, and user favorites.
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

Row level security is enabled. Brands, products, and tips are readable by
anonymous and authenticated users. Favorites are private to the signed-in user.

## Tests and checks

```bash
flutter analyze
flutter test
```
