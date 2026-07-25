// Read-only cutover monitor. Answers the one question that decides when the
// transition scaffolding can be deleted: how many pre-migration anonymous
// accounts are still unclaimed?
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/bridge_status.ts
//
// 14 accounts owning 54 journals (46% of the data) can only be recovered via
// the claim-anonymous bridge, and only while the Firebase session still exists
// on the user's device. That count should fall toward zero over the days after
// testers are forced onto the Supabase build. Watching it is strictly better
// than waiting for someone to report missing journals -- a user whose claim
// never fires sees an empty home screen and may simply assume the app lost
// their data rather than telling anyone.
//
// Deliberately standalone: unlike validate.ts this reads only the database and
// needs no export present, so it can be run at any moment during the window
// without first running a sync.
//
// NOT wired into sync.sh on purpose. sync.sh runs under `set -e`, so a
// non-zero exit here would mark an otherwise-successful sync as failed.

import { readFileSync } from "node:fs";
import admin from "firebase-admin";
import pg from "pg";
import { fail, requireEnv } from "./lib/env.ts";
import { Report } from "./lib/report.ts";

// assertPoolerUrl() is intentionally not called: it guards import_data's need
// for session mode (prepared statements, session-scoped temp tables). Nothing
// here is stateful, so the transaction pooler is perfectly fine.

type CohortRow = {
  username: string;
  firebase_uid: string;
  journals: number;
  is_placeholder: boolean;
  claimant_is_anonymous: boolean;
  claimed_at: Date;
  last_sign_in_at: Date | null;
};

function day(d: Date | null): string {
  return d ? d.toISOString().slice(0, 10) : "—";
}

/**
 * Is Firebase's Anonymous provider still disabled?
 *
 * It must stay that way. Disabling blocks `accounts:signUp` but NOT the
 * securetoken refresh path, so existing devices can still mint the ID token
 * the bridge needs -- while any surviving old build is prevented from creating
 * fresh anonymous orphans mid-cutover. Re-enabling it silently reopens that.
 *
 * Returns null when credentials are absent, so the DB half of this script
 * still runs for anyone without the service account.
 */
async function anonymousProviderEnabled(): Promise<boolean | null> {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath) return null;

  const sa = JSON.parse(readFileSync(credPath, "utf8"));
  const app = admin.apps.length
    ? admin.app()
    : admin.initializeApp({ credential: admin.credential.cert(sa) });
  const token = (await app.options.credential!.getAccessToken()).access_token;

  const res = await fetch(
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${sa.project_id}/config`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!res.ok) fail(`identitytoolkit config read failed: HTTP ${res.status}`);

  // The API omits the key entirely when the provider has never been enabled,
  // so "absent" and "explicitly false" both mean disabled.
  const cfg = (await res.json()) as { signIn?: { anonymous?: { enabled?: boolean } } };
  return cfg.signIn?.anonymous?.enabled === true;
}

async function main(): Promise<void> {
  const report = new Report("bridge_status");
  const pool = new pg.Pool({ connectionString: requireEnv("SUPABASE_DB_URL"), max: 2 });
  const c = await pool.connect();

  try {
    // ---- overall shape: migrated rows vs rows born in the new app
    const { rows: [p] } = await c.query(`
      select count(*)::int                                        as total,
             count(*) filter (where firebase_uid is not null)::int as migrated,
             count(*) filter (where firebase_uid is null)::int     as native
        from public.profiles`);
    report.count("profiles_total", p.total);
    report.count("profiles_migrated", p.migrated);
    report.count("profiles_created_in_new_app", p.native);

    const { rows: [j] } = await c.query(`
      select count(*)::int                                        as total,
             count(*) filter (where firestore_id is not null)::int as migrated,
             count(*) filter (where firestore_id is null)::int     as native
        from public.journals`);
    report.count("journals_total", j.total);
    report.count("journals_migrated", j.migrated);
    report.count("journals_created_in_new_app", j.native);

    // ---- THE cohort. Membership is defined by the ABSENCE of a provider
    // identity: firebase_identity_map is populated from providerUserInfo, and
    // an anonymous Firebase account has none. That definition is what makes
    // this script work after a claim -- the app_metadata.anonymous marker the
    // importer set lives on the PLACEHOLDER auth user, which the Edge Function
    // deletes on success, so anything keyed off it can only ever see the
    // not-yet-claimed half.
    //
    // Claimed vs unclaimed then falls out of whether the profile still points
    // at that placeholder. There is no "claimed" flag to maintain: a claim
    // re-points profiles.id to the claimant, so the marker disappears as a
    // consequence of the claim rather than as a separate write that could
    // drift from reality.
    const { rows: cohort } = await c.query<CohortRow>(`
      select p.username,
             p.firebase_uid,
             (select count(*) from public.journals x where x.user_id = p.id)::int as journals,
             ((u.raw_app_meta_data ->> 'anonymous')::boolean is true) as is_placeholder,
             u.is_anonymous    as claimant_is_anonymous,
             -- No claim timestamp is stored. The claimant's auth row is created
             -- by signInAnonymously() moments before the claim, so its
             -- created_at is an accurate proxy for "when the bridge fired".
             u.created_at      as claimed_at,
             u.last_sign_in_at
        from public.profiles p
        join auth.users u on u.id = p.id
       where p.firebase_uid is not null
         and not exists (select 1 from public.firebase_identity_map m
                          where m.firebase_uid = p.firebase_uid)
       order by journals desc, p.username`);

    const unclaimed = cohort.filter((r) => r.is_placeholder);
    const claimed = cohort.filter((r) => !r.is_placeholder);
    const sum = (rs: CohortRow[]) => rs.reduce((s, r) => s + r.journals, 0);

    report.count("anonymous_cohort_total", cohort.length);
    report.count("claimed_placeholders", claimed.length);
    report.count("claimed_journals_recovered", sum(claimed));
    report.count("unclaimed_placeholders", unclaimed.length);
    report.count("unclaimed_journals", sum(unclaimed));

    console.log(`\n--- claimed (bridge fired successfully) ---`);
    if (claimed.length === 0) {
      console.log("  none yet.");
    } else {
      for (const r of claimed) {
        // A claimant who is still on a Supabase anonymous session has no
        // credential to sign back in with: reinstalling loses the account
        // again, exactly as it would have before the migration.
        const fragile = r.claimant_is_anonymous ? "  anon-session" : "";
        console.log(
          `  ${r.username.padEnd(20)} ${String(r.journals).padStart(3)} journals   ` +
            `claimed ${day(r.claimed_at)}   last seen ${day(r.last_sign_in_at)}${fragile}`,
        );
      }
      console.log(`  ${claimed.length} accounts, ${sum(claimed)} journals recovered`);

      const fragile = claimed.filter((r) => r.claimant_is_anonymous).length;
      if (fragile > 0) {
        report.count("claimed_still_on_anonymous_session", fragile);
        console.log(
          `  note: ${fragile} claimed via a Supabase anonymous session and hold no\n` +
            `        sign-in credential — a reinstall would strand them again.`,
        );
      }
    }

    console.log(`\n--- unclaimed anonymous placeholders ---`);
    if (unclaimed.length === 0) {
      console.log("  none — every pre-migration anonymous account has been claimed.");
      console.log("  The bridge can be retired; see the post-migration cleanup issue.");
    } else {
      for (const r of unclaimed) {
        console.log(
          `  ${r.username.padEnd(20)} ${String(r.journals).padStart(3)} journals   ` +
            `${r.firebase_uid.slice(0, 10)}…`,
        );
      }
      console.log(`  ${unclaimed.length} accounts holding ${sum(unclaimed)} journals`);
    }

    // ---- placeholder auth users whose profile is already gone.
    // The Edge Function deletes the placeholder after re-pointing, but treats
    // a failure there as non-fatal (the claim already succeeded). These are
    // the leftovers that sweep-up is meant to collect -- harmless, but they
    // should be zero once nobody is mid-flight.
    const { rows: [orphan] } = await c.query(`
      select count(*)::int as n
        from auth.users u
        left join public.profiles p on p.id = u.id
       where (u.raw_app_meta_data ->> 'anonymous')::boolean is true
         and p.id is null`);
    report.count("placeholder_auth_users_without_profile", orphan.n);

    // ---- tombstones. Any kind='user' row for a firebase_uid that is still
    // waiting to be claimed is a genuine emergency: the delta-sync reads it as
    // "deleted in the new app" and will refuse to re-import that user's
    // journals for the rest of the window.
    const { rows: tombs } = await c.query(
      `select kind, count(*)::int as n from public.sync_tombstones group by kind`,
    );
    for (const t of tombs) report.count(`tombstones_${t.kind}`, t.n);

    // Scoped to every live migrated profile, not just the anonymous cohort: a
    // user tombstone against ANY of them has the same effect, and the pair
    // should never coexist. A tombstone means "deleted in the new app", which
    // is mutually exclusive with still having a profile row.
    const { rows: conflict } = await c.query<{ firebase_uid: string; username: string }>(`
      select p.firebase_uid, p.username
        from public.profiles p
        join public.sync_tombstones t
          on t.kind = 'user' and t.firestore_id = p.firebase_uid`);
    for (const r of conflict) {
      report.anomaly(
        "TOMBSTONE_FOR_LIVE_PROFILE",
        `${r.username} (${r.firebase_uid}): a user tombstone exists for a profile that ` +
          `is still live — the delta-sync reads it as "deleted in the new app" and will ` +
          `refuse to re-import this user's journals. Delete the tombstone before the next sync.`,
        { firebase_uid: r.firebase_uid, username: r.username },
      );
    }

    // ---- invariant: the Anonymous provider must stay off
    const anonEnabled = await anonymousProviderEnabled();
    if (anonEnabled === null) {
      report.count("firebase_provider_check_skipped");
      console.log("\n  (Firebase provider check skipped: GOOGLE_APPLICATION_CREDENTIALS unset)");
    } else if (anonEnabled) {
      report.anomaly(
        "ANONYMOUS_PROVIDER_ENABLED",
        "Firebase's Anonymous provider is ENABLED. Surviving old builds can now " +
          "mint fresh anonymous accounts, creating orphans that this migration " +
          "cannot bridge. Disable it in the Firebase console.",
      );
    } else {
      report.count("firebase_anonymous_provider_disabled");
    }
  } finally {
    c.release();
    await pool.end();
  }

  report.write();

  // Unclaimed placeholders are the EXPECTED state during the window, so they
  // never fail the run. Only a real misconfiguration does.
  process.exit(report.anomalyCount() > 0 ? 1 : 0);
}

await main();
