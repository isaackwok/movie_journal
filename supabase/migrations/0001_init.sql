-- Movie Journal initial schema.
-- Run once against a fresh Supabase project (or via `supabase db push`).

-- Users: one row per auth.users record. `id` is the Supabase auth UUID.
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

-- Journals: one row per saved journal entry.
create table public.journals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tmdb_id int not null,
  movie_title text not null,
  movie_poster text,
  emotions text[] not null default '{}',
  selected_scenes jsonb not null default '[]',
  selected_refs jsonb not null default '[]',
  thoughts text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index journals_user_id_idx on public.journals(user_id);

-- Row Level Security: lock everything to the owning user.
alter table public.users enable row level security;
alter table public.journals enable row level security;

-- Users can only CRUD their own row.
create policy "users_self_all" on public.users
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Allow reading the `username` column across users so that the CreateUser screen
-- can perform a uniqueness check on a username that doesn't belong to the
-- caller yet. We restrict it to `SELECT` only; inserts/updates stay locked by
-- the policy above.
create policy "users_username_readable" on public.users
  for select
  using (true);

-- Journals: owner-only.
create policy "journals_owner_all" on public.journals
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
