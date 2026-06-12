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
  total_waste_reduced numeric(10, 2) not null default 0,
  total_recycled_items integer not null default 0,
  total_food_saved numeric(10, 2) not null default 0,
  ranking text not null default 'Starter',
  weekly_progress integer[] not null default array[18, 22, 38, 30, 52, 41, 64],
  monthly_stats integer[] not null default array[0, 0, 0, 0, 0, 0],
  score_history integer[] not null default array[82],
  activities jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Eco Hero',
  email text not null default '',
  avatar_url text not null default '',
  avatar_path text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.saved_products (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.eco_products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.order_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  default_address text not null default '',
  delivery_notes text not null default '',
  prefer_plastic_free_packaging boolean not null default true,
  allow_substitutions boolean not null default true,
  carbon_neutral_shipping boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.support_issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  subject text not null,
  message text not null,
  contact_email text not null default '',
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  type text not null default 'general',
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.waste_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('reduced', 'recycled', 'food_saved', 'donated')),
  amount numeric(10, 2) not null check (amount > 0),
  unit text not null default 'kg',
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.eco_score_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score between 0 and 100),
  reason text not null default 'Eco action',
  created_at timestamptz not null default now()
);

alter table public.eco_products
  add column if not exists price numeric(10, 2) not null default 0,
  add column if not exists previous_price numeric(10, 2),
  add column if not exists eco_score integer not null default 80,
  add column if not exists co2_saved_kg numeric(10, 2) not null default 0,
  add column if not exists water_saved_liters integer not null default 0,
  add column if not exists material text not null default 'Sustainable materials',
  add column if not exists shipping_note text not null default 'Eco-conscious shipping available';

alter table public.impact_snapshots
  add column if not exists total_waste_reduced numeric(10, 2) not null default 0,
  add column if not exists total_recycled_items integer not null default 0,
  add column if not exists total_food_saved numeric(10, 2) not null default 0,
  add column if not exists ranking text not null default 'Starter',
  add column if not exists monthly_stats integer[] not null default array[0, 0, 0, 0, 0, 0],
  add column if not exists score_history integer[] not null default array[82];

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create index if not exists saved_products_user_idx
  on public.saved_products (user_id, created_at desc);
create index if not exists notifications_user_read_idx
  on public.notifications (user_id, read, created_at desc);
create index if not exists waste_records_user_created_idx
  on public.waste_records (user_id, created_at desc);
create index if not exists eco_score_history_user_created_idx
  on public.eco_score_history (user_id, created_at desc);

alter table public.notifications replica identity full;

alter table public.eco_brands enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_tips enable row level security;
alter table public.user_favorites enable row level security;
alter table public.impact_snapshots enable row level security;
alter table public.user_profiles enable row level security;
alter table public.saved_products enable row level security;
alter table public.order_preferences enable row level security;
alter table public.support_issues enable row level security;
alter table public.notifications enable row level security;
alter table public.waste_records enable row level security;
alter table public.eco_score_history enable row level security;

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

drop policy if exists "Users can read their own profile" on public.user_profiles;
create policy "Users can read their own profile"
  on public.user_profiles for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own profile" on public.user_profiles;
create policy "Users can create their own profile"
  on public.user_profiles for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own profile" on public.user_profiles;
create policy "Users can update their own profile"
  on public.user_profiles for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can read saved products" on public.saved_products;
create policy "Users can read saved products"
  on public.saved_products for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can save products" on public.saved_products;
create policy "Users can save products"
  on public.saved_products for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can unsave products" on public.saved_products;
create policy "Users can unsave products"
  on public.saved_products for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read order preferences" on public.order_preferences;
create policy "Users can read order preferences"
  on public.order_preferences for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert order preferences" on public.order_preferences;
create policy "Users can insert order preferences"
  on public.order_preferences for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update order preferences" on public.order_preferences;
create policy "Users can update order preferences"
  on public.order_preferences for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can create support issues" on public.support_issues;
create policy "Users can create support issues"
  on public.support_issues for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can read their support issues" on public.support_issues;
create policy "Users can read their support issues"
  on public.support_issues for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read notifications" on public.notifications;
create policy "Users can read notifications"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can update notifications" on public.notifications;
create policy "Users can update notifications"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can read waste records" on public.waste_records;
create policy "Users can read waste records"
  on public.waste_records for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can add waste records" on public.waste_records;
create policy "Users can add waste records"
  on public.waste_records for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update waste records" on public.waste_records;
create policy "Users can update waste records"
  on public.waste_records for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete waste records" on public.waste_records;
create policy "Users can delete waste records"
  on public.waste_records for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can read score history" on public.eco_score_history;
create policy "Users can read score history"
  on public.eco_score_history for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can upload profile photos" on storage.objects;
create policy "Users can upload profile photos"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update profile photos" on storage.objects;
create policy "Users can update profile photos"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete profile photos" on storage.objects;
create policy "Users can delete profile photos"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Profile photos are publicly readable" on storage.objects;
create policy "Profile photos are publicly readable"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'profile-photos');

create or replace function public.create_default_impact_snapshot()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (user_id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Eco Hero'),
    coalesce(new.email, '')
  )
  on conflict (user_id) do nothing;

  insert into public.order_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

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

  insert into public.notifications (user_id, title, body, type)
  values
    (
      new.id,
      'Welcome to EcoDiscover',
      'Your profile, tracker, and marketplace are ready.',
      'general'
    ),
    (
      new.id,
      'Eco Score started',
      'Add waste, recycling, food-saving, or donation records to grow your score.',
      'score'
    );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_impact_snapshot on auth.users;
create trigger on_auth_user_created_create_impact_snapshot
  after insert on auth.users
  for each row execute function public.create_default_impact_snapshot();

create or replace function public.recalculate_user_impact(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  reduced_total numeric(10, 2);
  recycled_total integer;
  food_total numeric(10, 2);
  donated_total integer;
  next_score integer;
  next_ranking text;
  next_weekly integer[];
  next_monthly integer[];
begin
  select
    coalesce(sum(amount) filter (where type = 'reduced'), 0),
    coalesce(sum(amount) filter (where type = 'recycled'), 0)::integer,
    coalesce(sum(amount) filter (where type = 'food_saved'), 0),
    coalesce(sum(amount) filter (where type = 'donated'), 0)::integer
  into reduced_total, recycled_total, food_total, donated_total
  from public.waste_records
  where user_id = target_user_id;

  next_score := least(
    100,
    greatest(
      0,
      round(50 + reduced_total * 1.2 + recycled_total * 0.5 + food_total * 2 + donated_total * 3)
    )
  )::integer;

  next_ranking := case
    when next_score >= 90 then 'Top 5%'
    when next_score >= 80 then 'Top 10%'
    when next_score >= 70 then 'Top 20%'
    else 'Growing'
  end;

  next_weekly := array[
    least(100, greatest(0, round(reduced_total)::integer)),
    least(100, greatest(0, recycled_total)),
    least(100, greatest(0, round(food_total * 2)::integer)),
    least(100, greatest(0, donated_total * 4)),
    least(100, greatest(0, next_score - 12)),
    least(100, greatest(0, next_score - 6)),
    next_score
  ];

  select array_agg(score order by created_at)
  into next_monthly
  from (
    select score, created_at
    from public.eco_score_history
    where user_id = target_user_id
    order by created_at desc
    limit 6
  ) recent_scores;

  if next_monthly is null or array_length(next_monthly, 1) = 0 then
    next_monthly := array[next_score];
  end if;

  insert into public.impact_snapshots (
    user_id,
    plastic_waste_reduction,
    food_waste_reduction,
    packaging_reduction,
    streak_days,
    eco_score,
    total_waste_reduced,
    total_recycled_items,
    total_food_saved,
    ranking,
    weekly_progress,
    monthly_stats,
    score_history,
    activities,
    updated_at
  )
  values (
    target_user_id,
    least(100, round(reduced_total * 4)::integer),
    least(100, round(food_total * 8)::integer),
    least(100, recycled_total * 2),
    greatest(1, (select count(*) from public.waste_records where user_id = target_user_id)),
    next_score,
    reduced_total,
    recycled_total,
    food_total,
    next_ranking,
    next_weekly,
    next_monthly,
    next_monthly,
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'title',
            case type
              when 'reduced' then 'Reduced waste'
              when 'recycled' then 'Recycled items'
              when 'food_saved' then 'Saved food'
              when 'donated' then 'Donated products'
              else 'Eco action'
            end,
            'subtitle',
            amount || ' ' || unit || case when note <> '' then ' - ' || note else '' end,
            'icon_name',
            type
          )
          order by created_at desc
        )
        from (
          select type, amount, unit, note, created_at
          from public.waste_records
          where user_id = target_user_id
          order by created_at desc
          limit 5
        ) latest_records
      ),
      '[]'::jsonb
    ),
    now()
  )
  on conflict (user_id) do update set
    plastic_waste_reduction = excluded.plastic_waste_reduction,
    food_waste_reduction = excluded.food_waste_reduction,
    packaging_reduction = excluded.packaging_reduction,
    streak_days = excluded.streak_days,
    eco_score = excluded.eco_score,
    total_waste_reduced = excluded.total_waste_reduced,
    total_recycled_items = excluded.total_recycled_items,
    total_food_saved = excluded.total_food_saved,
    ranking = excluded.ranking,
    weekly_progress = excluded.weekly_progress,
    monthly_stats = excluded.monthly_stats,
    score_history = excluded.score_history,
    activities = excluded.activities,
    updated_at = now();

  insert into public.eco_score_history (user_id, score, reason)
  values (target_user_id, next_score, 'Automatic Eco Score recalculation');

  insert into public.notifications (user_id, title, body, type)
  values (
    target_user_id,
    'Eco Score updated',
    'Your Eco Score is now ' || next_score || ' (' || next_ranking || ').',
    'score'
  );
end;
$$;

create or replace function public.on_waste_record_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.recalculate_user_impact(coalesce(new.user_id, old.user_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists waste_records_recalculate_impact on public.waste_records;
create trigger waste_records_recalculate_impact
  after insert or update or delete on public.waste_records
  for each row execute function public.on_waste_record_changed();

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
