-- ============ Tables ============
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  firebase_uid text unique,
  username text not null,
  created_at timestamptz not null default now(),
  -- Set ONLY by the app (username change). Importer never writes it;
  -- "is null" means "never edited in the new app" (sync conflict rule).
  updated_at timestamptz,
  migrated_updated_at timestamptz  -- source Firestore updatedAt at last sync
);
create unique index profiles_username_lower_key on public.profiles (lower(username));

create table public.journals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  tmdb_id integer not null,
  movie_title text not null default '',
  movie_poster text not null default '',
  emotions text[] not null default '{}',
  selected_scenes jsonb not null default '[]'::jsonb,  -- [{path, caption?}]
  selected_refs jsonb not null default '[]'::jsonb,    -- [{text, source}]
  thoughts text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  firestore_id text unique,          -- null for journals created in the new app
  migrated_updated_at timestamptz,   -- updated_at as imported at last sync;
                                     -- updated_at > migrated_updated_at = new-app edit
  raw jsonb                          -- verbatim original Firestore doc (zero-loss)
);
create index journals_user_id_idx on public.journals (user_id);

create table public.sync_tombstones (
  kind text not null check (kind in ('journal', 'user')),
  firestore_id text not null,  -- journal doc id, or firebase uid for kind='user'
  deleted_at timestamptz not null default now(),
  primary key (kind, firestore_id)
);

-- (provider, sub) -> firebase_uid, from firebase auth:export. Service-role only.
create table public.firebase_identity_map (
  provider text not null,       -- 'apple' | 'google'
  provider_sub text not null,   -- providerUserInfo[].rawId
  firebase_uid text not null,
  email text,
  primary key (provider, provider_sub)
);

-- ============ Data API grants ============
-- "Automatically expose new tables" is OFF on this project, so table privileges
-- must be explicit. This is also the future-proof form: Supabase removes
-- auto-exposure for ALL projects on 2026-10-30 (breaking change 2026-04-28).
grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.journals to authenticated;
-- The delete-account Edge Function reads journal ids through PostgREST as service_role:
grant select on table public.journals to service_role;
-- No `anon` grants anywhere: email auth is off, nothing is publicly readable.
-- No grants on sync_tombstones / firebase_identity_map — the migration scripts
-- connect over the pooler as the table owner, so they need none. A grant-less
-- table is unreachable via the Data API no matter what policies exist later.
-- profiles gets no DELETE: account deletion goes through the edge function.

-- ============ RLS ============
alter table public.profiles enable row level security;
alter table public.journals enable row level security;
alter table public.sync_tombstones enable row level security;       -- no policies
alter table public.firebase_identity_map enable row level security; -- no policies

create policy "profiles_select_own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
-- No delete policy: account deletion goes through the delete-account edge function.

create policy "journals_select_own" on public.journals
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "journals_insert_own" on public.journals
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "journals_update_own" on public.journals
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "journals_delete_own" on public.journals
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ============ Tombstone triggers ============
-- SECURITY DEFINER so cascade deletes (account deletion) write tombstones past RLS.
create or replace function public.record_journal_tombstone()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.firestore_id is not null then
    insert into public.sync_tombstones (kind, firestore_id)
    values ('journal', old.firestore_id) on conflict do nothing;
  end if;
  return old;
end;
$$;

create or replace function public.record_user_tombstone()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.firebase_uid is not null then
    insert into public.sync_tombstones (kind, firestore_id)
    values ('user', old.firebase_uid) on conflict do nothing;
  end if;
  return old;
end;
$$;

create trigger journals_tombstone_after_delete
  after delete on public.journals
  for each row execute function public.record_journal_tombstone();
create trigger profiles_tombstone_after_delete
  after delete on public.profiles
  for each row execute function public.record_user_tombstone();

-- ============ RPCs ============
-- Username availability (RLS blocks clients from scanning profiles).
-- SECURITY DEFINER but leaks only a boolean; authenticated-only.
create or replace function public.username_available(p_username text)
returns boolean language sql stable security definer set search_path = ''
as $$
  select not exists (
    select 1 from public.profiles where lower(username) = lower(p_username)
  );
$$;
revoke execute on function public.username_available(text) from public, anon;
grant execute on function public.username_available(text) to authenticated;

-- Safety net when email auto-linking did NOT attach the sign-in to the
-- pre-created user (e.g. provider email changed): match by provider sub
-- and re-point the pre-created data to the caller. No-op in the normal case.
create or replace function public.claim_migrated_data()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_firebase_uid text;
  v_old_id uuid;
  v_moved int := 0;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;

  if exists (select 1 from public.profiles where id = v_uid) then
    return jsonb_build_object('status', 'already_claimed');
  end if;

  select m.firebase_uid into v_firebase_uid
  from auth.identities i
  join public.firebase_identity_map m
    on m.provider = i.provider and m.provider_sub = i.provider_id
  where i.user_id = v_uid
  limit 1;

  if v_firebase_uid is null then
    return jsonb_build_object('status', 'no_mapping');
  end if;

  select id into v_old_id from public.profiles where firebase_uid = v_firebase_uid;
  if v_old_id is null then
    return jsonb_build_object('status', 'no_premigrated_profile');
  end if;

  update public.journals set user_id = v_uid where user_id = v_old_id;
  get diagnostics v_moved = row_count;
  update public.profiles set id = v_uid where id = v_old_id;

  return jsonb_build_object('status', 'claimed', 'journals_moved', v_moved);
end;
$$;
revoke execute on function public.claim_migrated_data() from public, anon;
grant execute on function public.claim_migrated_data() to authenticated;
