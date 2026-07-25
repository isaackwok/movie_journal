-- Remove incidental table privileges that anon / authenticated / service_role
-- inherit on every new table, so reality matches the initial schema's stated
-- intent ("No `anon` grants anywhere").
--
-- Where they come from: a migration's tables are owned by `postgres`, and the
-- `postgres` default ACL in schema public grants Dxtm to all three API roles:
--
--   postgres | r | postgres=arwdDxtm/postgres, anon=Dxtm/postgres,
--                  authenticated=Dxtm/postgres, service_role=Dxtm/postgres
--
--   a=INSERT r=SELECT w=UPDATE d=DELETE D=TRUNCATE x=REFERENCES t=TRIGGER m=MAINTAIN
--
-- No *data* privilege leaks (no a/r/w/d), so this was never a live hole, and
-- PostgREST issues only DML so none of it is reachable through the Data API.
-- But TRUNCATE bypasses row level security entirely, which makes it worth
-- removing outright rather than re-deriving that argument on every read.
--
-- MAINTAIN (m) is deliberately left in place: it permits VACUUM / ANALYZE /
-- REINDEX and grants no way to read or modify a single row.

revoke truncate, references, trigger
  on all tables in schema public
  from anon, authenticated, service_role;

-- The statement above only fixes tables that exist *right now*. Without this
-- second statement the next migration's CREATE TABLE silently re-inherits
-- Dxtm from the same default ACL and the problem quietly comes back.
alter default privileges in schema public
  revoke truncate, references, trigger
  on tables
  from anon, authenticated, service_role;

-- Not addressed here: a separate `supabase_admin` default ACL grants the API
-- roles full arwdDxtm. It applies only to tables created *by* supabase_admin --
-- migrations run as postgres, so it does not touch this schema -- and it is
-- Supabase-managed platform config, so it is left alone deliberately.
