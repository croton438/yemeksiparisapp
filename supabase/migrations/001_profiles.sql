-- 001_profiles.sql
-- Create profiles table and enable RLS

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  avatar_url text,
  created_at timestamptz default now()
);

-- Enable row level security
alter table profiles enable row level security;

-- Policy: Allow users to insert or update their own profile
create policy "profiles_user_is_owner" on profiles
  for all
  using (auth.uid() = id::text)
  with check (auth.uid() = id::text);

-- Note: Adjust id types to uuid if your auth.uid() returns uuid; cast as needed.
