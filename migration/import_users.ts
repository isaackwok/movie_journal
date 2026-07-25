// Pre-create Supabase Auth users from the Firebase auth export, and maintain
// firebase_identity_map.
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/import_users.ts
//
// Idempotent: safe to run every day of the transition window. Existing users
// are detected by app_metadata.firebase_uid and skipped.

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { createClient } from "@supabase/supabase-js";
import pg from "pg";
import { assertPoolerUrl, exportsDir, fail, requireEnv, runTs, supabaseSecretKey } from "./lib/env.ts";
import { Report } from "./lib/report.ts";

type ProviderInfo = { providerId: string; rawId: string; email?: string };
type AuthUser = {
  localId: string;
  email?: string;
  emailVerified?: boolean;
  createdAt?: string;
  providerUserInfo?: ProviderInfo[];
};

/** Firebase providerId -> the short name used in auth.identities / our map. */
const PROVIDER_MAP: Record<string, string> = {
  "apple.com": "apple",
  "google.com": "google",
};

/** RFC 2606 reserves .invalid, so this can never collide with a real address.
 *  Email auth is disabled, so these accounts are unreachable by sign-in; the
 *  claim-anonymous bridge is the only way in. */
function syntheticEmail(firebaseUid: string): string {
  return `fb-${firebaseUid.toLowerCase()}@anon.migrated.invalid`;
}

function isAnonymous(u: AuthUser): boolean {
  return !u.email && (u.providerUserInfo ?? []).length === 0;
}

async function main(): Promise<void> {
  const ts = runTs();
  const report = new Report("import_users");
  const dir = exportsDir(ts);
  const authPath = join(dir, "auth_users.json");

  let users: AuthUser[];
  try {
    users = JSON.parse(readFileSync(authPath, "utf8")).users;
  } catch {
    fail(`cannot read ${authPath} — run migration/export_auth.sh first (same RUN_TS)`);
  }
  if (!Array.isArray(users)) fail(`${authPath} has no users[] array`);
  report.count("auth_export_users", users.length);

  // ---------------------------------------------------------- PRE-FLIGHT
  // Runs over the WHOLE file before any write. Auto-linking merges accounts by
  // email, so two Firebase users sharing one email would silently collapse into
  // a single Supabase user and mix two people's journals together. That is
  // unrecoverable after the fact, so it aborts rather than reports.
  const byEmail = new Map<string, string[]>();
  for (const u of users) {
    if (!u.email) continue;
    const k = u.email.toLowerCase();
    byEmail.set(k, [...(byEmail.get(k) ?? []), u.localId]);
  }
  const dupes = [...byEmail.entries()].filter(([, ids]) => ids.length > 1);
  if (dupes.length) {
    for (const [email, ids] of dupes) {
      report.anomaly("duplicate_email", `${ids.length} Firebase users share ${email}`, { uids: ids });
    }
    report.write();
    fail(
      `ABORT: ${dupes.length} email(s) are shared by multiple Firebase users.\n` +
        "  Email auto-linking would merge them into one Supabase account and mix\n" +
        "  their journals. Resolve manually in Firebase before importing.",
    );
  }
  report.count("preflight_duplicate_emails", 0);

  const anonymous = users.filter(isAnonymous);
  const noEmailWithProvider = users.filter((u) => !u.email && (u.providerUserInfo ?? []).length > 0);
  for (const u of anonymous) {
    report.anomaly(
      "anonymous_user",
      `${u.localId}: no email and no provider — reachable only via the claim-anonymous bridge (decision 10)`,
      { firebase_uid: u.localId },
    );
  }
  for (const u of noEmailWithProvider) {
    report.anomaly("no_email_has_provider", `${u.localId}: no email; relies on claim_migrated_data`, {
      firebase_uid: u.localId,
    });
  }

  // ------------------------------------------------------------- clients
  const supabase = createClient(requireEnv("SUPABASE_URL"), supabaseSecretKey(), {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const dbUrl = requireEnv("SUPABASE_DB_URL");
  assertPoolerUrl(dbUrl);
  const pool = new pg.Pool({ connectionString: dbUrl, max: 4 });

  // Existing state. profiles.firebase_uid is the durable record of "already
  // imported"; tombstones record accounts deleted in the NEW app, which must
  // never be resurrected by a later sync.
  const client = await pool.connect();
  let existingUids: Set<string>;
  let tombstonedUids: Set<string>;
  try {
    existingUids = new Set(
      (await client.query("select firebase_uid from public.profiles where firebase_uid is not null")).rows.map(
        (r) => r.firebase_uid,
      ),
    );
    tombstonedUids = new Set(
      (await client.query("select firestore_id from public.sync_tombstones where kind = 'user'")).rows.map(
        (r) => r.firestore_id,
      ),
    );
  } finally {
    client.release();
  }
  report.count("already_in_profiles", existingUids.size);
  report.count("tombstoned_users", tombstonedUids.size);

  // Supabase users already carrying a firebase_uid, so a re-run after a crash
  // between createUser and the profiles insert does not create a duplicate.
  const existingByFirebaseUid = new Map<string, string>();
  for (let page = 1; ; page++) {
    const { data, error } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) fail(`listUsers failed: ${error.message}`);
    for (const u of data.users) {
      const fu = (u.app_metadata as Record<string, unknown> | undefined)?.firebase_uid;
      if (typeof fu === "string") existingByFirebaseUid.set(fu, u.id);
    }
    if (data.users.length < 1000) break;
  }
  report.count("supabase_users_with_firebase_uid", existingByFirebaseUid.size);

  // ---------------------------------------------------------- create pass
  const identityRows: Array<[string, string, string, string | null]> = [];

  for (const u of users) {
    const uid = u.localId;

    if (tombstonedUids.has(uid)) {
      report.count("skipped_tombstoned");
      continue;
    }
    if (existingUids.has(uid) || existingByFirebaseUid.has(uid)) {
      report.count("skipped_already_present");
    } else {
      const anon = isAnonymous(u);
      const email = u.email ?? syntheticEmail(uid);
      const providers = (u.providerUserInfo ?? [])
        .map((p) => PROVIDER_MAP[p.providerId])
        .filter(Boolean);

      const { data, error } = await supabase.auth.admin.createUser({
        email,
        email_confirm: true,
        app_metadata: {
          firebase_uid: uid,
          migrated_from: "firebase",
          providers,
          ...(anon ? { anonymous: true } : {}),
        },
      });

      if (error) {
        // Pre-existing account with the same email but a different (or absent)
        // firebase_uid means two identities are converging on one address --
        // exactly what the pre-flight guards against, but it can also arise
        // from a partial earlier run. Report and skip rather than guess.
        if (/already.*registered|already exists/i.test(error.message)) {
          const match = [...existingByFirebaseUid.entries()].find(([fu]) => fu === uid);
          if (match) {
            report.count("skipped_already_present");
          } else {
            report.anomaly(
              "email_exists_different_user",
              `${uid}: email already registered to a Supabase user without this firebase_uid — SKIPPED`,
              { firebase_uid: uid },
            );
          }
        } else {
          report.anomaly("create_user_failed", `${uid}: ${error.message}`, { firebase_uid: uid });
        }
      } else {
        existingByFirebaseUid.set(uid, data.user.id);
        report.count(anon ? "created_anonymous" : "created_federated");
      }
    }

    for (const p of u.providerUserInfo ?? []) {
      const provider = PROVIDER_MAP[p.providerId];
      if (!provider) {
        report.anomaly("unknown_provider", `${uid}: unmapped providerId ${p.providerId}`);
        continue;
      }
      if (!p.rawId) {
        report.anomaly("provider_no_raw_id", `${uid}: ${p.providerId} entry has no rawId`);
        continue;
      }
      identityRows.push([provider, p.rawId, uid, p.email ?? null]);
    }
  }

  // ------------------------------------------------- firebase_identity_map
  if (identityRows.length) {
    const c = await pool.connect();
    try {
      for (const [provider, sub, fbUid, email] of identityRows) {
        await c.query(
          `insert into public.firebase_identity_map (provider, provider_sub, firebase_uid, email)
           values ($1,$2,$3,$4)
           on conflict (provider, provider_sub) do update
             set firebase_uid = excluded.firebase_uid, email = excluded.email`,
          [provider, sub, fbUid, email],
        );
        report.count(`identity_map:${provider}`);
      }
    } finally {
      c.release();
    }
  }

  // --------------------------------------------- delta user-deletion pass
  // A firebase_uid present in profiles but ABSENT from the latest auth export
  // means the account was deleted in the OLD app. Propagate it -- but only if
  // the user never signed in on the new app. If auth.identities rows exist they
  // have adopted the new app, and deleting would destroy live data.
  const exportUids = new Set(users.map((u) => u.localId));
  const c2 = await pool.connect();
  try {
    const { rows } = await c2.query(
      `select p.id, p.firebase_uid,
              (select count(*) from auth.identities i where i.user_id = p.id) as identity_count
         from public.profiles p
        where p.firebase_uid is not null`,
    );
    for (const r of rows) {
      if (exportUids.has(r.firebase_uid)) continue;
      if (Number(r.identity_count) > 0) {
        report.anomaly(
          "deleted_in_firebase_but_active_in_supabase",
          `${r.firebase_uid}: gone from Firebase but has auth.identities — KEPT`,
          { firebase_uid: r.firebase_uid },
        );
        continue;
      }
      const { error } = await supabase.auth.admin.deleteUser(r.id);
      if (error) {
        report.anomaly("delete_user_failed", `${r.firebase_uid}: ${error.message}`);
      } else {
        report.count("deleted_old_app_account");
      }
    }
  } finally {
    c2.release();
  }

  await pool.end();
  report.write();

  if (anonymous.length) {
    console.log(
      `\nNOTE: ${anonymous.length} anonymous users pre-created with synthetic ` +
        `@anon.migrated.invalid emails. They cannot sign in until the ` +
        `claim-anonymous bridge ships (decision 10).`,
    );
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
