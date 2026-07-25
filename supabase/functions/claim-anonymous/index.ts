// Claims a pre-migration Firebase ANONYMOUS account's data (plan decision 10).
//
// Those 14 accounts have no email and no provider identity, so email
// auto-linking and claim_migrated_data() both structurally cannot find them.
// What their devices still hold is a live Firebase anonymous session, and a
// Firebase ID token is unforgeable proof of that uid — so it is the credential
// this function trades for ownership of the pre-created placeholder row.
//
// Flow: the app signs in to Supabase anonymously (creating a real auth.users
// row, which journals.user_id must FK to), then calls this with the Firebase
// ID token. Two identities are involved and they come from different places on
// purpose:
//
//   WHO AM I    -> the caller's own Supabase JWT (Authorization header)
//   WHAT MAY I CLAIM -> the uid inside the verified Firebase token (body)
//
// Taking the target account from the body instead of the header would let any
// caller re-point someone else's journals to themselves.

import { createClient } from "npm:@supabase/supabase-js@2";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

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
// Set at deploy: `supabase secrets set FIREBASE_PROJECT_ID=the-movie-journal`.
// Required rather than defaulted — a wrong or missing value must fail loudly at
// boot, not silently widen which tokens are accepted.
const FIREBASE_PROJECT_ID = requireEnv("FIREBASE_PROJECT_ID");

// Firebase publishes its ID-token signing keys in two formats. This is the
// JWKS one; the more commonly cited x509 endpoint serves PEM certificates,
// which jose cannot consume directly. Built once at module scope so the key
// cache survives warm starts instead of refetching per request.
const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const userClient = createClient(SUPABASE_URL, PUBLISHABLE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) return new Response("Unauthorized", { status: 401 });

  let firebaseIdToken: unknown;
  try {
    firebaseIdToken = (await req.json())?.firebaseIdToken;
  } catch {
    return Response.json({ error: "malformed JSON body" }, { status: 400 });
  }
  if (typeof firebaseIdToken !== "string" || firebaseIdToken.length === 0) {
    return Response.json(
      { error: "firebaseIdToken is required" },
      { status: 400 },
    );
  }

  // Full verification: signature against Firebase's published keys, plus the
  // issuer/audience/algorithm constraints Firebase documents for ID tokens.
  // Pinning `algorithms` matters — without it a token could name a weaker alg.
  let firebaseUid: string;
  try {
    const { payload } = await jwtVerify(firebaseIdToken, FIREBASE_JWKS, {
      issuer: `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`,
      audience: FIREBASE_PROJECT_ID,
      algorithms: ["RS256"],
    });
    // `sub` is the Firebase uid and Firebase guarantees it non-empty; checked
    // anyway because everything downstream treats it as an identity.
    if (typeof payload.sub !== "string" || payload.sub.length === 0) {
      return Response.json(
        { error: "firebase token has no subject" },
        { status: 401 },
      );
    }
    firebaseUid = payload.sub;
  } catch (e) {
    console.warn(`firebase token rejected for ${user.id}:`, (e as Error).message);
    return Response.json({ error: "invalid firebase token" }, { status: 401 });
  }

  const admin = createClient(SUPABASE_URL, SECRET_KEY);

  // One transaction moves the journals and the profile together. Doing it as
  // two PostgREST calls could strand journals under a profile that no longer
  // exists if the second failed.
  const { data, error: rpcErr } = await admin.rpc("claim_anonymous_data", {
    p_firebase_uid: firebaseUid,
    p_new_user_id: user.id,
  });
  if (rpcErr) {
    console.error(`claim_anonymous_data failed for ${user.id}:`, rpcErr.message);
    return Response.json({ error: rpcErr.message }, { status: 500 });
  }

  // The placeholder auth.users row is now orphaned — the RPC already moved its
  // profile and journals away, so this delete cascades to nothing and fires no
  // tombstone trigger. That ordering is what keeps the delta-sync working for
  // this user; see the migration's comment.
  //
  // Non-fatal: the claim has already succeeded and the user has their data.
  // A leftover row is exactly what the freeze-day cleanup step sweeps up
  // ("pre-created users with no profiles row").
  const placeholderId = (data as Record<string, unknown> | null)
    ?.placeholder_user_id;
  if (typeof placeholderId === "string") {
    const { error: delErr } = await admin.auth.admin.deleteUser(placeholderId);
    if (delErr) {
      console.warn(
        `placeholder ${placeholderId} left behind after claim by ${user.id}:`,
        delErr.message,
      );
    }
  }

  return Response.json(data);
});
