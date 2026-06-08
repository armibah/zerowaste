create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text not null default 'Eco Hero',
  avatar_url text,
  avatar_path text,
  updated_at timestamptz not null default now()
);

create table if not exists public.eco_brands (
  id text primary key,
  name text not null,
  tagline text not null default '',
  description text not null default '',
  logo_url text not null default '',
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.eco_products (
  id text primary key,
  brand_id text references public.eco_brands(id) on delete set null,
  brand_name text,
  name text not null,
  category text not null default 'General',
  description text not null default '',
  impact_label text not null default 'Low waste',
  image_url text not null default '',
  tags text[] not null default '{}',
  price numeric(10, 2) not null default 0,
  previous_price numeric(10, 2),
  eco_score integer not null default 75 check (eco_score between 0 and 100),
  co2_saved_kg numeric(10, 2) not null default 0,
  water_saved_liters integer not null default 0,
  material text not null default 'Sustainably sourced materials',
  shipping_note text not null default 'Plastic-free shipping available',
  created_at timestamptz not null default now()
);

create table if not exists public.eco_tips (
  id text primary key,
  title text not null,
  body text not null default '',
  icon_name text not null default 'eco',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.eco_products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create table if not exists public.order_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plastic_free_packaging boolean not null default true,
  contactless_delivery boolean not null default false,
  refill_reminders boolean not null default true,
  preferred_delivery_window text not null default 'Morning',
  delivery_notes text not null default '',
  updated_at timestamptz not null default now()
);

create table if not exists public.help_issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  body text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.waste_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default 'waste_reduced'
    check (type in ('waste_reduced', 'recycle', 'food_saved', 'donation')),
  amount_kg numeric(10, 2) not null default 0,
  recycled_items integer not null default 0,
  food_saved_kg numeric(10, 2) not null default 0,
  note text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.impact_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plastic_waste_reduction integer not null default 0,
  food_waste_reduction integer not null default 0,
  packaging_reduction integer not null default 0,
  streak_days integer not null default 0,
  eco_score integer not null default 0 check (eco_score between 0 and 100),
  weekly_progress integer[] not null default '{}',
  activities jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.eco_score_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score between 0 and 100),
  reason text not null default 'Eco activity',
  rank_label text not null default 'Community member',
  created_at timestamptz not null default now()
);

create index if not exists eco_products_brand_id_idx on public.eco_products(brand_id);
create index if not exists eco_products_category_idx on public.eco_products(category);
create index if not exists user_favorites_user_id_idx on public.user_favorites(user_id);
create index if not exists help_issues_user_created_idx on public.help_issues(user_id, created_at desc);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, read_at) where read_at is null;
create index if not exists waste_records_user_created_idx on public.waste_records(user_id, created_at desc);
create index if not exists eco_score_history_user_created_idx on public.eco_score_history(user_id, created_at desc);

alter table public.profiles enable row level security;
alter table public.eco_brands enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_tips enable row level security;
alter table public.user_favorites enable row level security;
alter table public.order_settings enable row level security;
alter table public.help_issues enable row level security;
alter table public.notifications enable row level security;
alter table public.waste_records enable row level security;
alter table public.impact_snapshots enable row level security;
alter table public.eco_score_history enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
for select using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "public_read_brands" on public.eco_brands;
create policy "public_read_brands" on public.eco_brands
for select using (true);

drop policy if exists "public_read_products" on public.eco_products;
create policy "public_read_products" on public.eco_products
for select using (true);

drop policy if exists "public_read_tips" on public.eco_tips;
create policy "public_read_tips" on public.eco_tips
for select using (true);

drop policy if exists "favorites_select_own" on public.user_favorites;
create policy "favorites_select_own" on public.user_favorites
for select using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on public.user_favorites;
create policy "favorites_insert_own" on public.user_favorites
for insert with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on public.user_favorites;
create policy "favorites_delete_own" on public.user_favorites
for delete using (auth.uid() = user_id);

drop policy if exists "order_settings_all_own" on public.order_settings;
create policy "order_settings_all_own" on public.order_settings
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "help_issues_select_own" on public.help_issues;
create policy "help_issues_select_own" on public.help_issues
for select using (auth.uid() = user_id);

drop policy if exists "help_issues_insert_own" on public.help_issues;
create policy "help_issues_insert_own" on public.help_issues
for insert with check (auth.uid() = user_id);

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
for select using (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "waste_records_select_own" on public.waste_records;
create policy "waste_records_select_own" on public.waste_records
for select using (auth.uid() = user_id);

drop policy if exists "waste_records_insert_own" on public.waste_records;
create policy "waste_records_insert_own" on public.waste_records
for insert with check (auth.uid() = user_id);

drop policy if exists "waste_records_update_own" on public.waste_records;
create policy "waste_records_update_own" on public.waste_records
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "waste_records_delete_own" on public.waste_records;
create policy "waste_records_delete_own" on public.waste_records
for delete using (auth.uid() = user_id);

drop policy if exists "impact_snapshots_select_own" on public.impact_snapshots;
create policy "impact_snapshots_select_own" on public.impact_snapshots
for select using (auth.uid() = user_id);

drop policy if exists "eco_score_history_select_own" on public.eco_score_history;
create policy "eco_score_history_select_own" on public.eco_score_history
for select using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "avatar_public_read" on storage.objects;
create policy "avatar_public_read" on storage.objects
for select using (bucket_id = 'avatars');

drop policy if exists "avatar_insert_own_folder" on storage.objects;
create policy "avatar_insert_own_folder" on storage.objects
for insert with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "avatar_update_own_folder" on storage.objects;
create policy "avatar_update_own_folder" on storage.objects
for update using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
) with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "avatar_delete_own_folder" on storage.objects;
create policy "avatar_delete_own_folder" on storage.objects
for delete using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Eco Hero')
  )
  on conflict (id) do nothing;

  insert into public.order_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.impact_snapshots (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.notifications (user_id, title, body)
  values (
    new.id,
    'Welcome to ZeroWaste',
    'Track waste, save products, and grow your Eco Score.'
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.recalculate_eco_score(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  total_waste numeric := 0;
  total_recycled integer := 0;
  total_food numeric := 0;
  new_score integer := 0;
  weekly integer[];
  activity_json jsonb;
  rank_label text;
begin
  select
    coalesce(sum(amount_kg), 0),
    coalesce(sum(recycled_items), 0),
    coalesce(sum(food_saved_kg), 0)
  into total_waste, total_recycled, total_food
  from public.waste_records
  where user_id = target_user_id;

  new_score := least(
    100,
    greatest(
      0,
      round(35 + total_waste * 3 + total_recycled * 1.5 + total_food * 4)::integer
    )
  );

  select coalesce(array_agg(day_total order by bucket_day), '{}'::integer[])
  into weekly
  from (
    select
      date_trunc('day', created_at)::date as bucket_day,
      least(100, round(sum(amount_kg + food_saved_kg) + sum(recycled_items))::integer) as day_total
    from public.waste_records
    where user_id = target_user_id
      and created_at >= now() - interval '6 days'
    group by 1
  ) daily;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'title',
        case type
          when 'recycle' then 'Recycled items'
          when 'food_saved' then 'Saved food'
          when 'donation' then 'Donated products'
          else 'Reduced waste'
        end,
        'subtitle',
        concat(amount_kg, 'kg reduced, ', recycled_items, ' items recycled'),
        'icon_name',
        type
      )
      order by created_at desc
    ),
    '[]'::jsonb
  )
  into activity_json
  from (
    select *
    from public.waste_records
    where user_id = target_user_id
    order by created_at desc
    limit 8
  ) recent;

  rank_label := case
    when new_score >= 90 then 'Top 5%'
    when new_score >= 75 then 'Top 15%'
    when new_score >= 60 then 'Top 30%'
    else 'Eco Starter'
  end;

  insert into public.impact_snapshots (
    user_id,
    plastic_waste_reduction,
    food_waste_reduction,
    packaging_reduction,
    streak_days,
    eco_score,
    weekly_progress,
    activities,
    updated_at
  )
  values (
    target_user_id,
    least(100, total_recycled),
    least(100, round(total_food)::integer),
    least(100, round(total_waste)::integer),
    greatest(1, (select count(distinct created_at::date) from public.waste_records where user_id = target_user_id)),
    new_score,
    weekly,
    activity_json,
    now()
  )
  on conflict (user_id) do update set
    plastic_waste_reduction = excluded.plastic_waste_reduction,
    food_waste_reduction = excluded.food_waste_reduction,
    packaging_reduction = excluded.packaging_reduction,
    streak_days = excluded.streak_days,
    eco_score = excluded.eco_score,
    weekly_progress = excluded.weekly_progress,
    activities = excluded.activities,
    updated_at = now();

  insert into public.eco_score_history (user_id, score, reason, rank_label)
  values (
    target_user_id,
    new_score,
    'Automatic recalculation from waste tracker records',
    rank_label
  );

  insert into public.notifications (user_id, title, body)
  values (
    target_user_id,
    'Eco Score updated',
    concat('Your Eco Score is now ', new_score, '.')
  );
end;
$$;

create or replace function public.recalculate_eco_score_from_record()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recalculate_eco_score(old.user_id);
    return old;
  end if;

  perform public.recalculate_eco_score(new.user_id);
  return new;
end;
$$;

drop trigger if exists waste_records_recalculate_score on public.waste_records;
create trigger waste_records_recalculate_score
after insert or update or delete on public.waste_records
for each row execute procedure public.recalculate_eco_score_from_record();

insert into public.eco_brands
  (id, name, tagline, description, logo_url, verified)
values
  ('refill-home', 'Refill Home', 'Reusable home essentials', 'Durable jars, refill stations, and low-waste kitchen staples.', '', true),
  ('root-and-fiber', 'Root & Fiber', 'Compostable personal care', 'Plant-based personal care products with recyclable paper packaging.', '', true),
  ('loop-market', 'Loop Market', 'Circular groceries', 'Local groceries delivered in returnable containers.', '', false)
on conflict (id) do update set
  name = excluded.name,
  tagline = excluded.tagline,
  description = excluded.description,
  logo_url = excluded.logo_url,
  verified = excluded.verified;

insert into public.eco_products
  (
    id,
    brand_id,
    brand_name,
    name,
    category,
    description,
    impact_label,
    image_url,
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
  ('bamboo-brush', 'root-and-fiber', 'Root & Fiber', 'Bamboo Toothbrush Kit', 'Personal Care', 'A soft-bristle toothbrush with a bamboo handle and recyclable travel sleeve.', 'Plastic-free handle', '', array['bamboo', 'travel', 'compostable'], 12.99, 16.99, 88, 1.8, 24, 'Moso bamboo and plant-based bristles', 'Ships in recyclable paper packaging'),
  ('glass-pantry-jars', 'refill-home', 'Refill Home', 'Stackable Glass Pantry Jars', 'Kitchen', 'Airtight jars for bulk grains, snacks, and refills with replaceable silicone seals.', 'Reusable for years', '', array['glass', 'bulk', 'kitchen'], 28.00, null, 92, 2.4, 38, 'Recycled glass and food-grade silicone', 'Carbon-neutral shipping on bundles'),
  ('cotton-produce-bags', 'loop-market', 'Loop Market', 'Organic Cotton Produce Bags', 'Grocery', 'Washable drawstring bags sized for produce, bread, and small pantry refills.', 'Replaces thin plastic bags', '', array['cotton', 'grocery', 'washable'], 18.50, 22.00, 84, 1.1, 18, 'GOTS organic cotton mesh', 'Packed without plastic mailers'),
  ('solid-dish-block', 'refill-home', 'Refill Home', 'Solid Dish Soap Block', 'Cleaning', 'Concentrated dish soap block that ships without water or plastic bottles.', 'Bottle-free cleaning', '', array['cleaning', 'soap', 'refill'], 9.99, null, 90, 1.6, 42, 'Plant oils, mineral scrub, paper wrap', 'Minimal paper wrap and recycled carton')
on conflict (id) do update set
  brand_id = excluded.brand_id,
  brand_name = excluded.brand_name,
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  impact_label = excluded.impact_label,
  image_url = excluded.image_url,
  tags = excluded.tags,
  price = excluded.price,
  previous_price = excluded.previous_price,
  eco_score = excluded.eco_score,
  co2_saved_kg = excluded.co2_saved_kg,
  water_saved_liters = excluded.water_saved_liters,
  material = excluded.material,
  shipping_note = excluded.shipping_note;

insert into public.eco_tips
  (id, title, body, icon_name, sort_order)
values
  ('swap-one', 'Start with one daily swap', 'Pick the single-use item you touch most often, then replace it with one reusable option.', 'leaf', 1),
  ('bulk-list', 'Bring a refill list', 'Keep a small note of pantry staples so bulk shopping stays quick and low-stress.', 'jar', 2),
  ('repair-first', 'Repair before replacing', 'Small fixes extend product life and usually save more impact than buying a greener replacement.', 'repair', 3)
on conflict (id) do update set
  title = excluded.title,
  body = excluded.body,
  icon_name = excluded.icon_name,
  sort_order = excluded.sort_order;
