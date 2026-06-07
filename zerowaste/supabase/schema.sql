-- EcoDiscover Supabase schema
-- Run this file in the Supabase SQL editor or with `supabase db push`.

create extension if not exists "pgcrypto";

create table if not exists public.eco_brands (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  tagline text not null default '',
  description text not null default '',
  logo_url text not null default '',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.eco_products (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid references public.eco_brands(id) on delete set null,
  slug text not null unique,
  name text not null,
  category text not null,
  description text not null default '',
  impact_label text not null default 'Low waste',
  image_url text not null default '',
  tags text[] not null default '{}',
  price numeric(10, 2) not null default 0,
  previous_price numeric(10, 2),
  eco_score integer not null default 80 check (eco_score between 0 and 100),
  co2_saved_kg numeric(10, 2) not null default 0,
  water_saved_liters integer not null default 0,
  material text not null default 'Sustainable materials',
  shipping_note text not null default 'Eco-conscious shipping available',
  created_at timestamptz not null default now()
);

create table if not exists public.eco_tips (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  body text not null default '',
  icon_name text not null default 'eco',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.eco_products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.impact_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plastic_waste_reduction integer not null default 70,
  food_waste_reduction integer not null default 45,
  packaging_reduction integer not null default 90,
  streak_days integer not null default 15,
  eco_score integer not null default 82 check (eco_score between 0 and 100),
  weekly_progress integer[] not null default array[18, 22, 38, 30, 52, 41, 64],
  activities jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.eco_products
  add column if not exists price numeric(10, 2) not null default 0,
  add column if not exists previous_price numeric(10, 2),
  add column if not exists eco_score integer not null default 80,
  add column if not exists co2_saved_kg numeric(10, 2) not null default 0,
  add column if not exists water_saved_liters integer not null default 0,
  add column if not exists material text not null default 'Sustainable materials',
  add column if not exists shipping_note text not null default 'Eco-conscious shipping available';

alter table public.eco_brands enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_tips enable row level security;
alter table public.user_favorites enable row level security;
alter table public.impact_snapshots enable row level security;

drop policy if exists "Eco brands are readable by everyone" on public.eco_brands;
create policy "Eco brands are readable by everyone"
  on public.eco_brands for select
  to anon, authenticated
  using (true);

drop policy if exists "Eco products are readable by everyone" on public.eco_products;
create policy "Eco products are readable by everyone"
  on public.eco_products for select
  to anon, authenticated
  using (true);

drop policy if exists "Eco tips are readable by everyone" on public.eco_tips;
create policy "Eco tips are readable by everyone"
  on public.eco_tips for select
  to anon, authenticated
  using (true);

drop policy if exists "Users can read their own favorites" on public.user_favorites;
create policy "Users can read their own favorites"
  on public.user_favorites for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can add their own favorites" on public.user_favorites;
create policy "Users can add their own favorites"
  on public.user_favorites for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can remove their own favorites" on public.user_favorites;
create policy "Users can remove their own favorites"
  on public.user_favorites for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read their own impact snapshot" on public.impact_snapshots;
create policy "Users can read their own impact snapshot"
  on public.impact_snapshots for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can upsert their own impact snapshot" on public.impact_snapshots;
create policy "Users can upsert their own impact snapshot"
  on public.impact_snapshots for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own impact snapshot" on public.impact_snapshots;
create policy "Users can update their own impact snapshot"
  on public.impact_snapshots for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.create_default_impact_snapshot()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.impact_snapshots (
    user_id,
    plastic_waste_reduction,
    food_waste_reduction,
    packaging_reduction,
    streak_days,
    eco_score,
    weekly_progress,
    activities
  )
  values (
    new.id,
    70,
    45,
    90,
    15,
    82,
    array[18, 22, 38, 30, 52, 41, 64],
    '[
      {
        "title": "Refilled water bottle",
        "subtitle": "Today, saved 2 plastic bottles",
        "icon_name": "bottle"
      },
      {
        "title": "Composted food scraps",
        "subtitle": "Yesterday, 0.5kg waste diverted",
        "icon_name": "compost"
      },
      {
        "title": "Used reusable bag",
        "subtitle": "June 3, avoided 4 bags",
        "icon_name": "bag"
      }
    ]'::jsonb
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_impact_snapshot on auth.users;
create trigger on_auth_user_created_create_impact_snapshot
  after insert on auth.users
  for each row execute function public.create_default_impact_snapshot();

insert into public.eco_brands (slug, name, tagline, description, verified)
values
  (
    'refill-home',
    'Refill Home',
    'Reusable home essentials',
    'Durable jars, refill stations, and low-waste kitchen staples for everyday households.',
    true
  ),
  (
    'root-and-fiber',
    'Root & Fiber',
    'Compostable personal care',
    'Plant-based personal care products packed in recyclable paper and compostable materials.',
    true
  ),
  (
    'loop-market',
    'Loop Market',
    'Circular groceries',
    'Local groceries delivered in returnable containers with pickup built into every order.',
    false
  )
on conflict (slug) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  verified = excluded.verified;

insert into public.eco_products (
  brand_id,
  slug,
  name,
  category,
  description,
  impact_label,
  tags,
  price,
  previous_price,
  eco_score,
  co2_saved_kg,
  water_saved_liters,
  material,
  shipping_note
)
values
  (
    (select id from public.eco_brands where slug = 'root-and-fiber'),
    'bamboo-brush',
    'Bamboo Toothbrush Kit',
    'Personal Care',
    'A soft-bristle toothbrush with a bamboo handle and recyclable travel sleeve.',
    'Plastic-free handle',
    array['bamboo', 'travel', 'compostable'],
    12.99,
    16.99,
    88,
    1.80,
    24,
    'Moso bamboo and plant-based bristles',
    'Ships in recyclable paper packaging'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'glass-pantry-jars',
    'Stackable Glass Pantry Jars',
    'Kitchen',
    'Airtight jars for bulk grains, snacks, and refills with replaceable silicone seals.',
    'Reusable for years',
    array['glass', 'bulk', 'kitchen'],
    28.00,
    null,
    92,
    2.40,
    38,
    'Recycled glass and food-grade silicone',
    'Carbon-neutral shipping on bundles'
  ),
  (
    (select id from public.eco_brands where slug = 'loop-market'),
    'cotton-produce-bags',
    'Organic Cotton Produce Bags',
    'Grocery',
    'Washable drawstring bags sized for produce, bread, and small pantry refills.',
    'Replaces thin plastic bags',
    array['cotton', 'grocery', 'washable'],
    18.50,
    22.00,
    84,
    1.10,
    18,
    'GOTS organic cotton mesh',
    'Packed without plastic mailers'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'solid-dish-block',
    'Solid Dish Soap Block',
    'Cleaning',
    'Concentrated dish soap block that ships without water or plastic bottles.',
    'Bottle-free cleaning',
    array['cleaning', 'soap', 'refill'],
    9.99,
    null,
    90,
    1.60,
    42,
    'Plant oils, mineral scrub, paper wrap',
    'Minimal paper wrap and recycled carton'
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'bamboo-travel-mug',
    'Premium Bamboo Travel Mug',
    'Drinkware',
    'A durable, BPA-free travel mug made from organic bamboo fibers. Keeps drinks hot for 6 hours and fits standard cup holders.',
    'Eco',
    array['bamboo', 'coffee', 'reusable'],
    24.00,
    32.00,
    94,
    2.80,
    57,
    'Bamboo fiber, recycled steel, silicone lid',
    'Plastic-free shipping and compostable ink labels'
  ),
  (
    (select id from public.eco_brands where slug = 'loop-market'),
    'steel-bento',
    'Steel Bento Lunch Box',
    'Kitchen',
    'Leak-resistant stainless bento for meal prep, takeout, and low-waste lunches.',
    'Reusable lunch kit',
    array['steel', 'meal prep', 'lunch'],
    34.00,
    null,
    89,
    3.20,
    22,
    'Food-grade stainless steel',
    'Ships in molded recycled paper'
  )
on conflict (slug) do update set
  brand_id = excluded.brand_id,
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  impact_label = excluded.impact_label,
  tags = excluded.tags,
  price = excluded.price,
  previous_price = excluded.previous_price,
  eco_score = excluded.eco_score,
  co2_saved_kg = excluded.co2_saved_kg,
  water_saved_liters = excluded.water_saved_liters,
  material = excluded.material,
  shipping_note = excluded.shipping_note;

insert into public.eco_tips (slug, title, body, icon_name, sort_order)
values
  (
    'swap-one',
    'Start with one daily swap',
    'Pick the single-use item you touch most often, then replace it with one reusable option.',
    'leaf',
    10
  ),
  (
    'bulk-list',
    'Bring a refill list',
    'Keep a small note of pantry staples so bulk shopping stays quick and low-stress.',
    'jar',
    20
  ),
  (
    'repair-first',
    'Repair before replacing',
    'Small fixes extend product life and usually save more impact than buying a greener replacement.',
    'repair',
    30
  )
on conflict (slug) do update set
  title = excluded.title,
  body = excluded.body,
  icon_name = excluded.icon_name,
  sort_order = excluded.sort_order;
