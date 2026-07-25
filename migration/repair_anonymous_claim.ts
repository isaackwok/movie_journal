// Manually re-point a pre-migration account's data onto a Supabase user the
// person can actually sign in as. The by-hand equivalent of claim_anonymous_data.
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/repair_anonymous_claim.ts \
//     --firebase-uid <old firebase uid> --to <target supabase user uuid>
//
// Dry run by default; add --confirm to write. Nothing here is reachable from
// the app — it needs the secret key and direct DB access.
//
// WHY THIS EXISTS
// ---------------
// AnonymousBridge recovers an anonymous account by trading the Firebase ID
// token still on the device. That makes recovery *device-bound*: reinstall the
// app, wipe it, or move to a new phone and the token is gone, and all three
// automatic paths fail at once —
//
//   - email auto-link      : the placeholder's email is synthetic
//                            (fb-<uid>@anon.migrated.invalid), matching nothing
//   - claim_migrated_data  : joins auth.identities, which an anonymous user has none of
//   - claim-anonymous      : needs the Firebase token that no longer exists
//
// The person then signs in normally, gets a fresh Supabase user, is sent to
// CreateUserScreen, and their journals sit stranded under the placeholder.
// That is the state this repairs. The Firebase token was only ever *proof of
// ownership*; with DB access you are asserting that proof out of band, so
// confirm identity by some other means before running this.
//
// ORDERING (the part with no undo)
// --------------------------------
// The profile must move BEFORE the placeholder auth user is deleted. Delete
// first and the cascade takes the profile with it, and the AFTER DELETE trigger
// writes a kind='user' tombstone keyed on firebase_uid — which import_users.ts
// reads as "deleted in the new app" and uses to skip that uid on EVERY future
// sync. That is unrecoverable without hand-deleting the tombstone. Same rule the
// claim-anonymous Edge Function follows, and the same reason.

import { createClient } from "@supabase/supabase-js";
import pg from "pg";
import { assertPoolerUrl, fail, requireEnv, supabaseSecretKey } from "./lib/env.ts";
import { Report } from "./lib/report.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Args = { firebaseUid: string; to: string; confirm: boolean };

function parseArgs(argv: string[]): Args {
  const get = (flag: string): string | undefined => {
    const i = argv.indexOf(flag);
    return i >= 0 ? argv[i + 1] : undefined;
  };

  const firebaseUid = get("--firebase-uid");
  const to = get("--to");
  const confirm = argv.includes("--confirm");

  if (!firebaseUid || !to) {
    fail(
      "usage: repair_anonymous_claim.ts --firebase-uid <uid> --to <supabase user uuid> [--confirm]\n" +
        "  --firebase-uid  the OLD Firebase uid, i.e. profiles.firebase_uid\n" +
        "  --to            the user id of the account they signed in as (auth.users.id)\n" +
        "  --confirm       actually write; omit to see the plan first",
    );
  }
  if (!UUID_RE.test(to)) fail(`--to must be a uuid, got: ${to}`);
  if (UUID_RE.test(firebaseUid)) {
    fail(
      `--firebase-uid looks like a uuid (${firebaseUid}).\n` +
        "  Firebase uids are 28-char strings; you have probably passed the Supabase\n" +
        "  id of the placeholder. Pass profiles.firebase_uid.",
    );
  }
  return { firebaseUid, to, confirm };
}

type Source = { id: string; username: string | null; journals: number };
type Target = { id: string; username: string | null; journals: number; hasProfile: boolean };

async function main(): Promise<void> {
  const { firebaseUid, to, confirm } = parseArgs(process.argv.slice(2));
  const report = new Report("repair_anonymous_claim");

  const dbUrl = requireEnv("SUPABASE_DB_URL");
  assertPoolerUrl(dbUrl);
  const pool = new pg.Pool({ connectionString: dbUrl, max: 2 });
  const admin = createClient(requireEnv("SUPABASE_URL"), supabaseSecretKey(), {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const blockers: string[] = [];
  const notes: string[] = [];

  const c = await pool.connect();
  let source: Source | null = null;
  let target: Target | null = null;

  try {
    // ---------------------------------------------------------- source side
    const srcRows = (
      await c.query(
        `select p.id, p.username,
                (select count(*) from public.journals j where j.user_id = p.id)::int as journals
           from public.profiles p where p.firebase_uid = $1`,
        [firebaseUid],
      )
    ).rows;

    if (srcRows.length === 0) {
      blockers.push(
        `no profile with firebase_uid=${firebaseUid}. Either the uid is wrong, or ` +
          `import_data has not run for this user.`,
      );
    } else if (srcRows.length > 1) {
      blockers.push(`${srcRows.length} profiles share firebase_uid=${firebaseUid} — refusing to guess`);
    } else {
      source = srcRows[0] as Source;
      if (source.id === to) {
        blockers.push("source and target are the same user — nothing to repair");
      }
      if (source.journals === 0) {
        // Not fatal on its own, but almost always means the wrong uid: the
        // whole point of a repair is data that is stranded.
        notes.push("source profile has ZERO journals — double-check the firebase_uid");
      }
    }

    // A tombstone here means a previous repair (or a deletion) ran in the wrong
    // order. Re-pointing now would leave import_users skipping this uid forever.
    const tomb = (
      await c.query(`select 1 from public.sync_tombstones where kind = 'user' and firestore_id = $1`, [
        firebaseUid,
      ])
    ).rowCount;
    if (tomb) {
      blockers.push(
        `a kind='user' tombstone exists for ${firebaseUid}. Every future sync will skip this ` +
          `user. Delete the tombstone first, and work out how it was written.`,
      );
    }

    // ---------------------------------------------------------- target side
    const { data: targetUser, error: targetErr } = await admin.auth.admin.getUserById(to);
    if (targetErr || !targetUser?.user) {
      blockers.push(`target auth user ${to} not found: ${targetErr?.message ?? "no user"}`);
    } else {
      const u = targetUser.user;
      const identities = u.identities ?? [];

      // The entire point is to land the data on something they can sign back
      // in as. Moving it onto another credential-less session would rebuild
      // the exact problem being repaired.
      if (u.is_anonymous || identities.length === 0) {
        blockers.push(
          `target ${to} has no provider identity (is_anonymous=${u.is_anonymous}). Repairing onto it ` +
            `would leave them exactly as stranded. Have them sign in with Apple/Google first, ` +
            `then pass that user id.`,
        );
      } else {
        notes.push(`target signs in with: ${identities.map((i) => i.provider).join(", ")}`);
      }

      if (typeof (u.app_metadata as Record<string, unknown>)?.firebase_uid === "string") {
        blockers.push(
          `target ${to} is itself a pre-created migration user ` +
            `(app_metadata.firebase_uid=${(u.app_metadata as Record<string, string>).firebase_uid}). ` +
            `Merging two migrated accounts is not what this script does.`,
        );
      }

      const tgtRows = (
        await c.query(
          `select p.id, p.username, p.firebase_uid,
                  (select count(*) from public.journals j where j.user_id = p.id)::int as journals
             from public.profiles p where p.id = $1`,
          [to],
        )
      ).rows;

      const tgtJournals = (
        await c.query(`select count(*)::int as n from public.journals where user_id = $1`, [to])
      ).rows[0].n as number;

      if (tgtJournals > 0) {
        blockers.push(
          `target ${to} already owns ${tgtJournals} journals. This script does not merge — ` +
            `decide by hand which set survives.`,
        );
      }

      if (tgtRows.length) {
        const t = tgtRows[0];
        // Deleting a profile that carries a firebase_uid fires the tombstone
        // trigger. A freshly-created profile has none, which is what makes the
        // delete in step 1 safe.
        if (t.firebase_uid !== null) {
          blockers.push(
            `target profile ${to} has firebase_uid=${t.firebase_uid}; deleting it would write a ` +
              `tombstone. Refusing.`,
          );
        }
        target = { id: to, username: t.username, journals: tgtJournals, hasProfile: true };
      } else {
        target = { id: to, username: null, journals: tgtJournals, hasProfile: false };
      }
    }

    // ------------------------------------------------------------- the plan
    console.log("\n=== repair_anonymous_claim ===");
    console.log(`  firebase_uid   ${firebaseUid}`);
    console.log(`  source profile ${source?.id ?? "(not found)"}  username=${source?.username ?? "-"}  journals=${source?.journals ?? 0}`);
    console.log(`  target user    ${target?.id ?? to}  existing profile=${target?.hasProfile ?? "?"}  journals=${target?.journals ?? "?"}`);
    for (const n of notes) console.log(`  note: ${n}`);

    if (blockers.length) {
      for (const b of blockers) report.anomaly("blocked", b);
      console.error("\nBLOCKED — nothing was written:");
      for (const b of blockers) console.error(`  - ${b}`);
      report.write();
      await pool.end();
      process.exit(1);
    }

    console.log("\n  will:");
    if (target!.hasProfile) console.log(`    1. delete the empty profile ${to} (firebase_uid is null -> no tombstone)`);
    console.log(`    2. move ${source!.journals} journals  ${source!.id} -> ${to}`);
    console.log(`    3. move the profile row  ${source!.id} -> ${to}  (username "${source!.username}" is restored)`);
    console.log(`    4. delete the orphaned placeholder auth user ${source!.id}`);

    if (!confirm) {
      console.log("\n  DRY RUN — re-run with --confirm to apply.\n");
      report.count("dry_run");
      report.write();
      await pool.end();
      return;
    }

    // ------------------------------------------------------------- execute
    // Steps 1-3 are one transaction: a partial application would leave the
    // journals and their profile pointing at different users.
    await c.query("begin");
    try {
      if (target!.hasProfile) {
        await c.query(`delete from public.profiles where id = $1 and firebase_uid is null`, [to]);
        report.count("deleted_empty_target_profile");
      }
      const moved = await c.query(`update public.journals set user_id = $1 where user_id = $2`, [
        to,
        source!.id,
      ]);
      report.count("journals_moved", moved.rowCount ?? 0);

      await c.query(`update public.profiles set id = $1 where id = $2`, [to, source!.id]);
      report.count("profiles_moved");

      await c.query("commit");
    } catch (e) {
      await c.query("rollback");
      throw e;
    }

    // Verify against the database rather than trusting the row counts above.
    const after = (
      await c.query(
        `select (select count(*)::int from public.journals where user_id = $1) as journals,
                (select count(*)::int from public.profiles where id = $1) as profile,
                (select count(*)::int from public.profiles where id = $2) as stale`,
        [to, source!.id],
      )
    ).rows[0];
    if (after.profile !== 1 || after.stale !== 0 || after.journals !== source!.journals) {
      report.anomaly(
        "post_verify_mismatch",
        `after repair: journals=${after.journals} (expected ${source!.journals}), ` +
          `profile=${after.profile}, stale=${after.stale}`,
      );
      console.error("\nWARNING: post-repair state is not what was expected — inspect before continuing.");
    } else {
      console.log(`\n  moved ${after.journals} journals and the profile onto ${to}`);
    }
  } finally {
    c.release();
  }

  // Step 4, deliberately AFTER the commit. The profile no longer points at the
  // placeholder, so this cascades to nothing and fires no tombstone. Non-fatal:
  // the repair has already succeeded, and a leftover row is what the freeze-day
  // cleanup sweeps up.
  const { error: delErr } = await admin.auth.admin.deleteUser(source!.id);
  if (delErr) {
    report.anomaly("placeholder_delete_failed", `${source!.id}: ${delErr.message}`);
    console.warn(`\n  placeholder ${source!.id} left behind: ${delErr.message}`);
  } else {
    report.count("placeholder_deleted");
  }

  await pool.end();
  report.write();
  console.log("\n  Have them relaunch the app — the journals will be on their account.\n");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
