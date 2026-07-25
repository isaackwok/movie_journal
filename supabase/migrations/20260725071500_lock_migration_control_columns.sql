-- Take the migration-bookkeeping columns away from the client.
--
-- WHY RLS DID NOT ALREADY DO THIS: a policy decides which ROWS a statement may
-- touch. It says nothing about which COLUMNS. Column authority lives entirely
-- in the GRANT, and `grant update on table` means every column, forever. So
-- journals_update_own -- "(select auth.uid()) = user_id", which is correct --
-- still lets a signed-in user rewrite the delta-sync's bookkeeping on their own
-- row. Both statements below were reproduced against a real Postgres as the
-- `authenticated` role before this migration was written.
--
-- The failure that matters, because it damages ANOTHER user:
--
--   update public.journals set firestore_id = '<a Firestore doc id>' where id = <mine>;
--   delete from public.journals where id = <mine>;
--
-- The AFTER DELETE trigger writes a kind='journal' tombstone for a doc id the
-- attacker does not own, and import_data.ts reads sync_tombstones as "deleted
-- in the new app" and skips that journal for the rest of the transition window.
-- It is the same hazard claim_anonymous_data() is carefully ordered to avoid
-- for kind='user' -- except reachable by anyone with a session and curl, since
-- PostgREST is the API and the Flutter client is not a security boundary.
--
-- The quieter one: profiles.firebase_uid is the key claim_anonymous_data()
-- looks up to find a bridged user's placeholder row. It is unique, so a
-- squatter cannot take a uid that is already imported -- but it should not be
-- client-writable at all, and clearing your own strands you from the sync.
--
-- THE ALLOWLISTS BELOW ARE EXACTLY WHAT lib/supabase_db_manager.dart SENDS.
-- If journalToRow() or the profiles writers gain a column, add it here or that
-- write starts failing with 403. Two entries look wrong and are not:
--   * user_id IS in the journals UPDATE list. journalToRow() always includes
--     it, even on update, so omitting it 403s every journal edit. WITH CHECK
--     is what stops it being pointed at another user -- never the grant.
--   * created_at is NOT in the journals UPDATE list. updateJournal() already
--     omits it (includeCreatedAt: false); this promotes "an edit preserves
--     created_at" from a client convention to a database guarantee.

revoke insert, update on public.journals from authenticated;
grant insert (user_id, tmdb_id, movie_title, movie_poster, emotions,
              selected_scenes, selected_refs, thoughts, created_at, updated_at)
  on public.journals to authenticated;
grant update (user_id, tmdb_id, movie_title, movie_poster, emotions,
              selected_scenes, selected_refs, thoughts, updated_at)
  on public.journals to authenticated;
-- Deliberately ungranted on both: id (server default), firestore_id,
-- migrated_updated_at, raw. All four are importer-owned.

revoke insert, update on public.profiles from authenticated;
grant insert (id, username) on public.profiles to authenticated;
grant update (username, updated_at) on public.profiles to authenticated;
-- Deliberately ungranted on both: firebase_uid, created_at,
-- migrated_updated_at. All three are importer-owned.

-- SELECT stays table-wide on purpose: every column is the caller's own data,
-- and `raw` is just the verbatim Firestore doc they already own.

-- ============ Default ACL for functions ============
-- The same shape of problem 20260725033216 fixed for tables: the built-in
-- default ACL for a function grants EXECUTE to PUBLIC, and PUBLIC includes
-- anon -- so a future SECURITY DEFINER function in this schema is callable
-- without signing in unless someone remembers to revoke. Every function so far
-- does remember; the goal was to stop relying on remembering.
--
-- IT DOES NOT WORK HERE, AND THE STATEMENT IS KEPT ONLY SO NOBODY RE-ADDS IT
-- BELIEVING IT DOES. Measured on Supabase Postgres 17.6 from a clean
-- `supabase db reset`: the row lands in pg_default_acl as expected
-- (postgres | {postgres=X/postgres}), but a function created afterwards by
-- postgres in this schema still comes out with proacl = NULL -- the built-in
-- default -- and has_function_privilege('anon', fn, 'EXECUTE') is still true.
-- The equivalent REVOKE for *tables* does take effect (its probe passes in
-- rls_smoke.sql), so this is specific to functions on this platform.
--
-- Real enforcement therefore lives in rls_smoke.sql, which asserts that no
-- callable function in `public` is anon-executable and that exactly two are
-- authenticated-executable. A new function without its revoke fails the suite,
-- which is the outcome this statement was supposed to buy.
alter default privileges in schema public
  revoke execute on functions from public, anon;

-- Advisor hygiene, not a fix: Postgres already refuses to invoke these
-- directly ("trigger functions can only be called as triggers"), so the
-- inherited PUBLIC grant was never reachable through PostgREST. Revoking it
-- clears two WARN rows so the advisor list stays worth reading.
--
-- Safe because PostgreSQL checks EXECUTE on a trigger function at CREATE
-- TRIGGER time, not at fire time -- verified after this migration by deleting
-- a migrated journal as `authenticated` and asserting the tombstone appears.
revoke execute on function public.record_journal_tombstone()
  from public, anon, authenticated;
revoke execute on function public.record_user_tombstone()
  from public, anon, authenticated;

-- ============ Username shape ============
-- validateUsername() in lib/features/login/screens/create_user.dart is the
-- only thing enforcing username shape today, and PostgREST does not run it:
-- the publishable key ships in the binary by design, so any HTTP client with
-- a session can write this column directly. This constraint is a backstop for
-- that path, NOT a replacement -- the client check stays, and stays the place
-- that produces good error messages.
--
-- It is deliberately LOOSER than validateUsername(), which additionally
-- rejects trailing '_'/'.' and all-punctuation names. That asymmetry is the
-- point: the client owns the product rule, the database owns "nothing insane
-- gets stored". Anything this constraint rejects but the client accepts
-- surfaces as an unhandled 23514 -- createUser() only maps 23505 -- so the
-- database must never be the stricter of the two.
--
-- Hence {1,30} and not {2,30}: validateUsername() accepts a 1-character name.
-- All 26 production usernames satisfy this (checked 2026-07-25 against prod:
-- lengths 2-13, all matching ^[A-Za-z0-9_.]+$), so there is no backfill risk.
--
-- The 30-char ceiling is mirrored by rule 4 of validateUsername(), so the UI
-- reports it with a message instead of letting Postgres raise 23514. If you
-- change the number here, change it there too -- it is the one part of this
-- constraint the client must agree with exactly.
alter table public.profiles
  add constraint profiles_username_shape
  check (username ~ '^[A-Za-z0-9_.]{1,30}$');
