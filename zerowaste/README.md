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
- Supabase Storage profile photos with upload, update, delete, validation, and
  per-user storage policies.
- Saved products that persist in Supabase after logout/login.
- Order settings, Help Center issue submission, realtime notifications, waste
  records, automatic tracker totals, and Eco Score history.
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
- `user_profiles`
- `saved_products`
- `order_preferences`
- `support_issues`
- `notifications`
- `waste_records`
- `eco_score_history`

Row level security is enabled. Brands, products, and tips are readable by
anonymous and authenticated users. Favorites and impact snapshots are private to
the signed-in user.

The schema also creates a public Supabase Storage bucket named
`profile-photos`. Users can only upload, update, and delete files under their
own user-id folder.

Waste tracker records automatically recalculate:

- total waste reduced
- total recycled items
- total food saved
- weekly/monthly stats
- Eco Score
- ranking
- Eco Score history
- score notifications

## Main Flutter files

- `lib/main.dart` initializes Supabase and switches between live/demo services.
- `lib/screens/login_screen.dart` contains the sign-up and login UI.
- `lib/screens/home_screen.dart` contains the home, product, tracker,
  marketplace, profile, and product detail designs.
- `lib/services/eco_repository.dart` contains Supabase queries and demo data.
- `lib/models/` contains typed models for profile, notifications, order
  settings, help issues, waste records, and Eco Score history.

## Tests and checks

```bash
flutter analyze
flutter test
```
