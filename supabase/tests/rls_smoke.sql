-- RLS smoke test for the initial schema (plan Phase 2 gate).
--
-- Run with:  supabase test db
--
-- Why `set local role authenticated` appears everywhere below: postgres is a
-- superuser and BYPASSES row level security outright. Asserting policy
-- behaviour while connected as postgres passes no matter how broken the
-- policies are. Fixtures are inserted as postgres (deliberately, to bypass
-- RLS), then every assertion runs after switching to the `authenticated` role
-- with request.jwt.claims set -- which is what makes auth.uid() resolve.

begin;
-- Explicit count (not no_plan) so a test that silently stops running is caught.
select plan(46);

-- ---------------------------------------------------------------- fixtures
-- Two users. Fixed UUIDs so failures are reproducible.
\set user_a '11111111-1111-1111-1111-111111111111'
\set user_b '22222222-2222-2222-2222-222222222222'

insert into auth.users (id, email, aud, role)
values (:'user_a', 'a@example.com', 'authenticated', 'authenticated'),
       (:'user_b', 'b@example.com', 'authenticated', 'authenticated');

insert into public.profiles (id, firebase_uid, username)
values (:'user_a', 'fb_a', 'alice'),
       (:'user_b', 'fb_b', 'bob');

insert into public.journals (id, user_id, tmdb_id, movie_title, firestore_id)
values ('aaaaaaaa-0000-0000-0000-000000000001', :'user_a', 550, 'Fight Club', 'fs_a1'),
       ('aaaaaaaa-0000-0000-0000-000000000002', :'user_a', 551, 'Se7en',      'fs_a2'),
       ('bbbbbbbb-0000-0000-0000-000000000001', :'user_b', 552, 'Alien',      'fs_b1');

-- ------------------------------------------------- grant surface (pre-RLS)
-- RLS only matters if the role holds the underlying table privilege at all.
select ok(has_table_privilege('authenticated','public.journals','SELECT'),
          'authenticated has SELECT on journals (GRANT block applied)');
select ok(has_table_privilege('authenticated','public.profiles','UPDATE'),
          'authenticated has UPDATE on profiles');
select ok(not has_table_privilege('authenticated','public.profiles','DELETE'),
          'authenticated has NO DELETE on profiles (deletion goes via edge function)');
select ok(not has_table_privilege('authenticated','public.sync_tombstones','SELECT'),
          'authenticated cannot read sync_tombstones');
select ok(not has_table_privilege('authenticated','public.firebase_identity_map','SELECT'),
          'authenticated cannot read firebase_identity_map');

-- anon must hold no data privilege on anything.
select ok(not has_table_privilege('anon','public.journals','SELECT'),  'anon cannot SELECT journals');
select ok(not has_table_privilege('anon','public.journals','INSERT'),  'anon cannot INSERT journals');
select ok(not has_table_privilege('anon','public.profiles','SELECT'),  'anon cannot SELECT profiles');
select ok(not has_table_privilege('anon','public.firebase_identity_map','SELECT'),
          'anon cannot SELECT firebase_identity_map');

-- Incidental privileges revoked (20260725033216). TRUNCATE matters most: it
-- bypasses RLS entirely, so a stray grant would undo every policy below.
select ok(not has_table_privilege('anon','public.journals','TRUNCATE'),
          'anon cannot TRUNCATE journals (TRUNCATE bypasses RLS)');
select ok(not has_table_privilege('authenticated','public.journals','TRUNCATE'),
          'authenticated cannot TRUNCATE journals');
select ok(not has_table_privilege('service_role','public.journals','TRUNCATE'),
          'service_role cannot TRUNCATE journals');
select ok(not has_table_privilege('anon','public.profiles','REFERENCES'),
          'anon has no REFERENCES on profiles');

-- The default ACL must be fixed too, else the *next* migration's table
-- silently re-inherits Dxtm. Prove it against a table created right here.
create table public.__acl_probe (id int);
select ok(not has_table_privilege('anon','public.__acl_probe','TRUNCATE'),
          'a newly created table does NOT re-inherit TRUNCATE for anon');
select ok(not has_table_privilege('authenticated','public.__acl_probe','TRUNCATE'),
          'a newly created table does NOT re-inherit TRUNCATE for authenticated');
drop table public.__acl_probe;

-- Every table has RLS armed.
select ok((select relrowsecurity from pg_class where oid = 'public.journals'::regclass),  'journals RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),  'profiles RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.sync_tombstones'::regclass),
          'sync_tombstones RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.firebase_identity_map'::regclass),
          'firebase_identity_map RLS enabled');

-- ------------------------------------------------------- act as user A
set local role authenticated;
select set_config('request.jwt.claims',
                  json_build_object('sub', '11111111-1111-1111-1111-111111111111',
                                    'role', 'authenticated')::text, true);

select is((select auth.uid()), '11111111-1111-1111-1111-111111111111'::uuid,
          'auth.uid() resolves from request.jwt.claims');

-- SELECT isolation
select is((select count(*) from public.journals)::int, 2,
          'A sees exactly their own 2 journals');
select is((select count(*) from public.journals
           where user_id = '22222222-2222-2222-2222-222222222222')::int, 0,
          'A sees 0 of B''s journals');
select is((select count(*) from public.profiles)::int, 1,
          'A sees exactly 1 profile (their own)');

-- UPDATE isolation: the USING clause must filter B's rows out entirely.
with upd as (
  update public.journals set thoughts = 'tampered'
  where user_id = '22222222-2222-2222-2222-222222222222' returning 1
)
select is((select count(*) from upd)::int, 0, 'A''s UPDATE of B''s journals affects 0 rows');

-- DELETE isolation
with del as (
  delete from public.journals
  where user_id = '22222222-2222-2222-2222-222222222222' returning 1
)
select is((select count(*) from del)::int, 0, 'A''s DELETE of B''s journals affects 0 rows');

-- WITH CHECK: A must not be able to re-assign their own row to B.
-- Without a WITH CHECK clause this UPDATE would succeed and silently hand a
-- row to another user -- the USING clause alone does not prevent it.
select throws_ok(
  $$update public.journals set user_id = '22222222-2222-2222-2222-222222222222'
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '42501',
  null,
  'A cannot reassign own journal to B (WITH CHECK enforced)');

-- INSERT WITH CHECK: A cannot create a journal owned by B.
select throws_ok(
  $$insert into public.journals (user_id, tmdb_id) values
    ('22222222-2222-2222-2222-222222222222', 999)$$,
  '42501',
  null,
  'A cannot INSERT a journal owned by B');

-- Privileged tables are unreachable even with RLS on (no grants at all).
select throws_ok($$select 1 from public.sync_tombstones$$, '42501', null,
                 'authenticated denied on sync_tombstones');
select throws_ok($$select 1 from public.firebase_identity_map$$, '42501', null,
                 'authenticated denied on firebase_identity_map');

-- RPC reachable by authenticated, and honest about taken names.
select ok(public.username_available('brand_new_name'), 'username_available true for free name');
select ok(not public.username_available('BOB'), 'username_available false for taken name, case-insensitive');

-- ------------------------------------------------- tombstone triggers
-- The delta-sync propagates deletions through sync_tombstones. Phase 4 warns
-- this can stop working silently, so assert the triggers actually fire --
-- including the negative case, which is what distinguishes "trigger works"
-- from "trigger writes a row for everything".
delete from public.journals where id = 'aaaaaaaa-0000-0000-0000-000000000001';  -- firestore_id fs_a1

-- A new-app journal (firestore_id null) must NOT produce a tombstone: there is
-- nothing in Firestore to propagate the delete to.
insert into public.journals (id, user_id, tmdb_id, firestore_id)
values ('aaaaaaaa-0000-0000-0000-000000000009',
        '11111111-1111-1111-1111-111111111111', 777, null);
delete from public.journals where id = 'aaaaaaaa-0000-0000-0000-000000000009';

reset role;  -- back to postgres; authenticated holds no grant on sync_tombstones

select is((select count(*) from public.sync_tombstones
           where kind = 'journal' and firestore_id = 'fs_a1')::int, 1,
          'deleting a migrated journal writes a journal tombstone');
select is((select count(*) from public.sync_tombstones where kind = 'journal')::int, 1,
          'a journal with null firestore_id writes NO tombstone');

delete from public.profiles where id = '22222222-2222-2222-2222-222222222222';
select is((select count(*) from public.sync_tombstones
           where kind = 'user' and firestore_id = 'fb_b')::int, 1,
          'deleting a migrated profile writes a user tombstone');

-- ------------------------------------ claim_anonymous_data (decision 10)
-- This function takes a firebase_uid as an ASSERTION of identity. Whoever can
-- call it can re-point that uid's journals to themselves, so the entire
-- security of the anonymous bridge is "only the Edge Function may execute it".
-- Verifying the Firebase ID token is what earns the call; these three
-- assertions are what stop anyone skipping that step.
select ok(not has_function_privilege('authenticated',
            'public.claim_anonymous_data(text, uuid)', 'EXECUTE'),
          'authenticated CANNOT execute claim_anonymous_data (identity is asserted, not proven)');
select ok(not has_function_privilege('anon',
            'public.claim_anonymous_data(text, uuid)', 'EXECUTE'),
          'anon cannot execute claim_anonymous_data');
select ok(has_function_privilege('service_role',
            'public.claim_anonymous_data(text, uuid)', 'EXECUTE'),
          'service_role can execute claim_anonymous_data');

-- Fresh fixtures: a pre-created placeholder (P) holding a migrated anonymous
-- user's data, and the real anonymous account (N) their device just created.
\set user_p '33333333-3333-3333-3333-333333333333'
\set user_n '44444444-4444-4444-4444-444444444444'

insert into auth.users (id, email, aud, role)
values (:'user_p', 'fb-anon1@anon.migrated.invalid', 'authenticated', 'authenticated'),
       (:'user_n', null, 'authenticated', 'authenticated');

insert into public.profiles (id, firebase_uid, username)
values (:'user_p', 'fb_anon1', 'anon_user');

insert into public.journals (id, user_id, tmdb_id, firestore_id)
values ('cccccccc-0000-0000-0000-000000000001', :'user_p', 601, 'fs_p1'),
       ('cccccccc-0000-0000-0000-000000000002', :'user_p', 602, 'fs_p2');

create temp table claim_1 as
select public.claim_anonymous_data('fb_anon1', :'user_n'::uuid) as r;

select is((select r->>'status' from claim_1), 'claimed',
          'claim_anonymous_data reports claimed');
select is((select r->>'journals_moved' from claim_1), '2',
          'both journals moved to the caller');
select is((select count(*) from public.journals where user_id = :'user_n')::int, 2,
          'journals are now owned by the real anonymous account');
select is((select count(*) from public.profiles where id = :'user_n')::int, 1,
          'profile was re-pointed to the caller');

-- firebase_uid must survive the re-point, or the daily delta-sync loses track
-- of which Firestore docs belong to this user for the rest of the window.
select is((select firebase_uid from public.profiles where id = :'user_n'),
          'fb_anon1',
          'firebase_uid is preserved so delta-sync keeps matching this user');

-- The subtle one. Re-pointing must not look like a deletion: a kind='user'
-- tombstone here would tell the delta-sync this account was deleted in the new
-- app, and it would then refuse to re-import their journals. This is why the
-- profile is UPDATEd before the placeholder auth user is deleted, never after.
select is((select count(*) from public.sync_tombstones
           where kind = 'user' and firestore_id = 'fb_anon1')::int, 0,
          'claiming writes NO user tombstone (would break delta-sync)');

-- Idempotent: the app retries on every cold start until it gets a response.
select is((select public.claim_anonymous_data('fb_anon1', :'user_n'::uuid)->>'status'),
          'already_claimed',
          'a second claim is a no-op, not an error');

select is((select public.claim_anonymous_data('fb_unknown', :'user_n'::uuid)->>'status'),
          'already_claimed',
          'a caller who already has a profile short-circuits before any lookup');

insert into auth.users (id, email, aud, role)
values ('55555555-5555-5555-5555-555555555555', null, 'authenticated', 'authenticated');
select is((select public.claim_anonymous_data('fb_nonexistent',
             '55555555-5555-5555-5555-555555555555'::uuid)->>'status'),
          'no_premigrated_profile',
          'an unknown firebase_uid claims nothing');

select * from finish();
rollback;
