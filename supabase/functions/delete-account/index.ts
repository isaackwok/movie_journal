// Supabase Edge Function: delete-account
//
// The Supabase client SDK cannot delete its own auth user — only the service
// role can call `auth.admin.deleteUser`. This function is invoked from the
// Flutter client (`SupabaseManager.deleteAccount()`) after re-authentication
// and after `public.users` / `public.journals` rows have been removed. The ON
// DELETE CASCADE foreign keys would also drop those rows, but we clean them up
// client-side first so analytics per-journal events fire before the account is
// gone.
//
// Deploy: `supabase functions deploy delete-account`
// Required secrets: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (set by the
// Supabase platform automatically for functions).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "missing_authorization" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ error: "misconfigured" }), {
        status: 500,
        headers: { "content-type": "application/json" },
      });
    }

    // Resolve the caller's user id from their JWT.
    const userClient = createClient(supabaseUrl, serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userResult, error: userError } = await userClient.auth.getUser();
    if (userError || !userResult?.user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { "content-type": "application/json" },
      });
    }

    // Use an admin client (service role, no Authorization header) to delete.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(
      userResult.user.id,
    );
    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
        headers: { "content-type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }
});
