-- 002_addresses_orders.sql

create table if not exists addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  city text,
  district text,
  neighborhood text,
  line text,
  note text,
  created_at timestamptz default now()
);

alter table addresses enable row level security;
create policy "addresses_owner" on addresses for all
  using (auth.uid() = user_id::text)
  with check (auth.uid() = user_id::text);

-- Orders
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  restaurant_id text,
  total integer,
  payment_method text,
  status text default 'pending',
  delivery_address jsonb,
  created_at timestamptz default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id text,
  name text,
  unit_price integer,
  quantity integer,
  selections jsonb
);

alter table orders enable row level security;
create policy "orders_owner" on orders for all
  using (auth.uid() = user_id::text)
  with check (auth.uid() = user_id::text);
