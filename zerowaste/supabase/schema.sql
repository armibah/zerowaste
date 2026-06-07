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

alter table public.eco_brands enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_tips enable row level security;
alter table public.user_favorites enable row level security;

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
  tags
)
values
  (
    (select id from public.eco_brands where slug = 'root-and-fiber'),
    'bamboo-brush',
    'Bamboo Toothbrush Kit',
    'Personal Care',
    'A soft-bristle toothbrush with a bamboo handle and recyclable travel sleeve.',
    'Plastic-free handle',
    array['bamboo', 'travel', 'compostable']
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'glass-pantry-jars',
    'Stackable Glass Pantry Jars',
    'Kitchen',
    'Airtight jars for bulk grains, snacks, and refills with replaceable silicone seals.',
    'Reusable for years',
    array['glass', 'bulk', 'kitchen']
  ),
  (
    (select id from public.eco_brands where slug = 'loop-market'),
    'cotton-produce-bags',
    'Organic Cotton Produce Bags',
    'Grocery',
    'Washable drawstring bags sized for produce, bread, and small pantry refills.',
    'Replaces thin plastic bags',
    array['cotton', 'grocery', 'washable']
  ),
  (
    (select id from public.eco_brands where slug = 'refill-home'),
    'solid-dish-block',
    'Solid Dish Soap Block',
    'Cleaning',
    'Concentrated dish soap block that ships without water or plastic bottles.',
    'Bottle-free cleaning',
    array['cleaning', 'soap', 'refill']
  )
on conflict (slug) do update set
  brand_id = excluded.brand_id,
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  impact_label = excluded.impact_label,
  tags = excluded.tags;

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
