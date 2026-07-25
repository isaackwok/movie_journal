// Deletes the calling user's account.
//
// Deleting the auth.users row cascades to profiles and journals (both FK to
// auth.users ON DELETE CASCADE), and the AFTER DELETE triggers write
// sync_tombstones rows so the delta-sync propagates the deletion back to
// Firestore during the transition window.
//
// Journal ids are collected BEFORE the delete so the client can log
// per-journal analytics, matching the Firebase flow it replaces.

import { createClient } from "npm:@supabase/supabase-js@2";

// The plan flagged both of these names as "verify at deploy". Local Supabase
// injects the legacy SUPABASE_* names; projects created with the newer API key
// format may expose SB_PUBLISHABLE_KEY / SB_SECRET_KEY instead. Accept either
// rather than betting on one and failing at runtime with an opaque 500.
function requireEnv(...names: string[]): string {
  for (const n of names) {
    const v = Deno.env.get(n);
    if (v) return v;
  }
  throw new Error(`none of these env vars are set: ${names.join(", ")}`);
}

const SUPABASE_URL = requireEnv("SUPABASE_URL");
const PUBLISHABLE_KEY = requireEnv("SUPABASE_ANON_KEY", "SB_PUBLISHABLE_KEY");
const SECRET_KEY = requireEnv("SUPABASE_SERVICE_ROLE_KEY", "SB_SECRET_KEY");

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const userClient = createClient(SUPABASE_URL, PUBLISHABLE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) return new Response("Unauthorized", { status: 401 });

  const admin = createClient(SUPABASE_URL, SECRET_KEY);

  // service_role has BYPASSRLS, so this sees the user's rows without needing
  // an RLS policy of its own (it holds only a SELECT grant on journals).
  const { data: journals, error: selErr } = await admin
    .from("journals").select("id").eq("user_id", user.id);

  // Deliberately non-fatal. Account deletion is a user right; refusing to
  // delete because an analytics read failed is the wrong trade. Log it so the
  // gap is visible instead of silently returning an empty id list.
  if (selErr) {
    console.error(`journal id collection failed for ${user.id}:`, selErr.message);
  }

  // Phase 0 verification saw a single transient 403 bad_jwt from the admin API
  // that did not reproduce on retry. One bounded retry rather than surfacing a
  // spurious failure to a user who is trying to delete their account.
  let delErr = (await admin.auth.admin.deleteUser(user.id)).error;
  if (delErr) {
    console.warn(`deleteUser failed for ${user.id}, retrying once:`, delErr.message);
    await new Promise((r) => setTimeout(r, 250));
    delErr = (await admin.auth.admin.deleteUser(user.id)).error;
  }
  if (delErr) return new Response(delErr.message, { status: 500 });

  return Response.json({
    deletedJournalIds: (journals ?? []).map((j) => j.id),
    journalIdsIncomplete: Boolean(selErr),
  });
});
