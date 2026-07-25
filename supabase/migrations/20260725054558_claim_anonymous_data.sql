-- Anonymous-account bridge (plan decision 10).
--
-- 14 pre-migration Firebase accounts are anonymous: no email, no provider,
-- owning 54 journals (46% of production data). Neither of the plan's other
-- linking paths can identify them — email auto-linking has no email to match,
-- and claim_migrated_data() joins on auth.identities, which an anonymous user
-- has none of. The one credential that still proves ownership is the Firebase
-- anonymous session on their device.
--
-- The claim-anonymous Edge Function verifies that Firebase ID token against
-- Firebase's public JWKS and calls this function with the uid it contains.
--
-- SECURITY: p_firebase_uid is an *assertion of identity*. Anyone able to call
-- this with an arbitrary uid could steal that user's journals, so execute is
-- granted to service_role ONLY — never to authenticated. Verifying the token
-- is what earns the right to call this, and the Edge Function is the only
-- thing holding the service key.
create or replace function public.claim_anonymous_data(
  p_firebase_uid text,
  p_new_user_id uuid
)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_old_id uuid;
  v_moved int := 0;
begin
  if p_firebase_uid is null or p_new_user_id is null then
    raise exception 'firebase_uid and new_user_id are both required';
  end if;

  -- Idempotent: re-running after a dropped response must not error. The app
  -- retries on every cold start until it succeeds.
  if exists (select 1 from public.profiles where id = p_new_user_id) then
    return jsonb_build_object('status', 'already_claimed');
  end if;

  select id into v_old_id
  from public.profiles
  where firebase_uid = p_firebase_uid;

  if v_old_id is null then
    return jsonb_build_object('status', 'no_premigrated_profile');
  end if;

  -- Re-point data to the caller BEFORE the Edge Function deletes the
  -- placeholder auth user. Order matters: deleting that user while its profile
  -- still pointed at it would cascade the profile away, and the AFTER DELETE
  -- trigger would write a kind='user' tombstone — which the delta-sync reads
  -- as "this account was deleted in the new app" and would then refuse to
  -- re-import their journals for the rest of the transition window.
  update public.journals set user_id = p_new_user_id where user_id = v_old_id;
  get diagnostics v_moved = row_count;

  -- Keeps firebase_uid on the row, so the daily delta-sync continues to match
  -- this user's Firestore docs to their (now real) Supabase account.
  update public.profiles set id = p_new_user_id where id = v_old_id;

  return jsonb_build_object(
    'status', 'claimed',
    'journals_moved', v_moved,
    'placeholder_user_id', v_old_id
  );
end;
$$;

revoke execute on function public.claim_anonymous_data(text, uuid)
  from public, anon, authenticated;
grant execute on function public.claim_anonymous_data(text, uuid) to service_role;
