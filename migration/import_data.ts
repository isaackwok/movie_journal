// Transform exported Firestore docs and upsert them into Postgres.
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/import_data.ts
//
// This IS the delta-sync body: idempotent, conflict-aware, and safe to run
// daily while old app versions keep writing to Firestore.
//
// Uses `pg` rather than PostgREST because the conflict rules are conditional
// ("only overwrite if the incoming row is newer", "never overwrite a username
// the new app changed"), which PostgREST's upsert cannot express.

import { readFileSync } from "node:fs";
import { join } from "node:path";
import pg from "pg";
import { assertPoolerUrl, exportsDir, fail, requireEnv, runTs } from "./lib/env.ts";
import { Report } from "./lib/report.ts";
import {
  type ExportedDoc,
  isValidUsername,
  toUtcIso,
  transformJournal,
} from "./lib/transform.ts";

function readJsonl(path: string): ExportedDoc[] {
  let text: string;
  try {
    text = readFileSync(path, "utf8");
  } catch {
    fail(`cannot read ${path} — run migration/export_firestore.ts first (same RUN_TS)`);
  }
  return text
    .split("\n")
    .filter((l) => l.trim() !== "")
    .map((l) => JSON.parse(l));
}

/**
 * Resolve username collisions before touching the database.
 *
 * profiles has a UNIQUE index on lower(username), but Firestore only enforced
 * uniqueness in the app, so duplicates exist (production has one: "isaac" x2).
 * Oldest createdAt keeps the original name -- renaming the newer account is the
 * least surprising choice, and it is stable across re-runs because it depends
 * only on exported data, never on database state or iteration order.
 */
function dedupeUsernames(
  docs: ExportedDoc[],
  report: Report,
): Map<string, string> {
  const chosen = new Map<string, string>(); // firebase_uid -> final username
  const taken = new Set<string>(); // lowercased

  const entries = docs.map((d) => {
    let name = typeof d.data.username === "string" ? d.data.username.trim() : "";
    if (name === "") {
      name = `user_${d.id.slice(0, 8)}`;
      report.anomaly("username_missing", `${d.id}: no username, generated "${name}"`, { uid: d.id });
    }
    const created = typeof d.data.createdAt === "string" ? d.data.createdAt : (d.createTime ?? "");
    return { uid: d.id, name, created };
  });

  // Oldest first, so the earliest account keeps its name. Tie-break on uid so
  // the result is deterministic even when timestamps are identical.
  entries.sort((a, b) => (a.created === b.created ? a.uid.localeCompare(b.uid) : a.created.localeCompare(b.created)));

  for (const e of entries) {
    let candidate = e.name;
    if (taken.has(candidate.toLowerCase())) {
      let n = 2;
      while (taken.has(`${e.name}_${n}`.toLowerCase())) n++;
      candidate = `${e.name}_${n}`;
      report.anomaly(
        "username_collision_renamed",
        `${e.uid}: "${e.name}" already taken, renamed to "${candidate}"`,
        { uid: e.uid, from: e.name, to: candidate },
      );
    }
    if (!isValidUsername(candidate)) {
      const fallback = `user_${e.uid.slice(0, 8)}`;
      report.anomaly(
        "username_invalid",
        `${e.uid}: "${candidate}" fails validateUsername, using "${fallback}"`,
        { uid: e.uid, from: candidate, to: fallback },
      );
      candidate = fallback;
    }
    taken.add(candidate.toLowerCase());
    chosen.set(e.uid, candidate);
  }
  return chosen;
}

async function main(): Promise<void> {
  const ts = runTs();
  const report = new Report("import_data");
  const dir = exportsDir(ts);

  const userDocs = readJsonl(join(dir, "users.jsonl"));
  const journalDocs = readJsonl(join(dir, "journals.jsonl"));
  report.count("export_users", userDocs.length);
  report.count("export_journals", journalDocs.length);

  const dbUrl = requireEnv("SUPABASE_DB_URL");
  assertPoolerUrl(dbUrl);
  const pool = new pg.Pool({ connectionString: dbUrl, max: 4 });

  // firebase_uid -> supabase auth user id, written by import_users.
  const uidMap = new Map<string, string>();
  {
    const c = await pool.connect();
    try {
      const { rows } = await c.query(
        `select id, raw_app_meta_data->>'firebase_uid' as firebase_uid
           from auth.users where raw_app_meta_data->>'firebase_uid' is not null`,
      );
      for (const r of rows) uidMap.set(r.firebase_uid, r.id);
    } finally {
      c.release();
    }
  }
  report.count("mapped_auth_users", uidMap.size);

  const tombUsers = new Set<string>();
  const tombJournals = new Set<string>();
  {
    const c = await pool.connect();
    try {
      const { rows } = await c.query("select kind, firestore_id from public.sync_tombstones");
      for (const r of rows) (r.kind === "user" ? tombUsers : tombJournals).add(r.firestore_id);
    } finally {
      c.release();
    }
  }

  // ----------------------------------------------------------- profiles
  const usernames = dedupeUsernames(userDocs, report);
  {
    const c = await pool.connect();
    try {
      for (const doc of userDocs) {
        const fbUid = doc.id;
        if (tombUsers.has(fbUid)) {
          report.count("profile_skipped_tombstoned");
          continue;
        }
        const authId = uidMap.get(fbUid);
        if (!authId) {
          report.anomaly("profile_no_auth_user", `${fbUid}: no Supabase auth user — run import_users first`, {
            firebase_uid: fbUid,
          });
          continue;
        }
        const created = toUtcIso(doc.data.createdAt, doc.createTime, report, `profile ${fbUid}.createdAt`);
        const srcUpdated = toUtcIso(
          doc.data.updatedAt ?? doc.data.createdAt,
          doc.updateTime,
          report,
          `profile ${fbUid}.updatedAt`,
        );
        const username = usernames.get(fbUid)!;

        // `where profiles.updated_at is null` is the conflict rule: updated_at
        // is set ONLY by the new app on a username change, so a non-null value
        // means the user renamed themselves and the old Firestore value must
        // never clobber it.
        // The `updated_at is null` clause is the plan's conflict rule. The
        // `is distinct from` clause is an addition: without it the UPDATE fires
        // on every run, rewriting identical values 26 times a day and burying
        // genuine changes in the report. The plan's own gate is "second run is
        // a no-op", and this is what makes that literally true for profiles as
        // it already is for journals.
        const sql = `insert into public.profiles (id, firebase_uid, username, created_at, migrated_updated_at)
                     values ($1,$2,$3,$4,$5)
                     on conflict (firebase_uid) do update
                       set username = excluded.username,
                           migrated_updated_at = excluded.migrated_updated_at
                     where public.profiles.updated_at is null
                       and (public.profiles.username is distinct from excluded.username
                            or public.profiles.migrated_updated_at is distinct from excluded.migrated_updated_at)`;
        try {
          const res = await c.query(sql, [authId, fbUid, username, created.iso, srcUpdated.iso]);
          // rowCount 0 means the conflict WHERE filtered the update out: either
          // the new app owns this username now (updated_at not null) or nothing
          // actually changed. Both are "leave it alone", so one counter.
          report.count(res.rowCount ? "profile_written" : "profile_unchanged");
        } catch (e: any) {
          if (e?.code === "23505") {
            // Raced against a username that exists in the DB but not in this
            // export (e.g. created in the new app). Suffix and retry once.
            const alt = `${username}_${Math.floor(Date.now() / 1000) % 10000}`;
            report.anomaly("username_conflict_in_db", `${fbUid}: "${username}" taken in DB, used "${alt}"`, {
              firebase_uid: fbUid,
              to: alt,
            });
            await c.query(sql, [authId, fbUid, alt, created.iso, srcUpdated.iso]);
            report.count("profile_written");
          } else {
            throw e;
          }
        }
      }
    } finally {
      c.release();
    }
  }

  // ----------------------------------------------------------- journals
  {
    const c = await pool.connect();
    try {
      for (const doc of journalDocs) {
        if (tombJournals.has(doc.id)) {
          report.count("journal_skipped_tombstoned");
          continue;
        }
        const row = transformJournal(doc, report);
        if (!row) continue;
        if (tombUsers.has(row.firebase_uid)) {
          report.count("journal_skipped_owner_tombstoned");
          continue;
        }
        const authId = uidMap.get(row.firebase_uid);
        if (!authId) {
          report.anomaly(
            "journal_unmapped_owner",
            `${doc.id}: owner ${row.firebase_uid} has no Supabase user — SKIPPED (must be 0 after import_users)`,
            { firestore_id: doc.id, firebase_uid: row.firebase_uid },
          );
          continue;
        }

        const res = await c.query(
          `insert into public.journals
             (user_id, tmdb_id, movie_title, movie_poster, emotions, selected_scenes,
              selected_refs, thoughts, created_at, updated_at, firestore_id,
              migrated_updated_at, raw)
           values ($1,$2,$3,$4,$5,$6::jsonb,$7::jsonb,$8,$9,$10,$11,$10,$12::jsonb)
           on conflict (firestore_id) do update set
             tmdb_id = excluded.tmdb_id, movie_title = excluded.movie_title,
             movie_poster = excluded.movie_poster, emotions = excluded.emotions,
             selected_scenes = excluded.selected_scenes, selected_refs = excluded.selected_refs,
             thoughts = excluded.thoughts, created_at = excluded.created_at,
             updated_at = excluded.updated_at, migrated_updated_at = excluded.migrated_updated_at,
             raw = excluded.raw
           where public.journals.updated_at < excluded.updated_at`,
          [
            authId, row.tmdb_id, row.movie_title, row.movie_poster, row.emotions,
            JSON.stringify(row.selected_scenes), JSON.stringify(row.selected_refs),
            row.thoughts, row.created_at, row.updated_at, row.firestore_id,
            JSON.stringify(row.raw),
          ],
        );
        report.count(res.rowCount ? "journal_written" : "journal_unchanged");
      }
    } finally {
      c.release();
    }
  }

  // ------------------------------------------- old-app deletion propagation
  // MUST run on ONE checked-out client: the temp table is session-scoped, and
  // pool.query() would happily send the CREATE and the DELETE down different
  // connections. Get this wrong and deletions silently stop propagating.
  {
    const c = await pool.connect();
    try {
      await c.query("begin");
      await c.query("create temp table _export_ids (firestore_id text primary key) on commit drop");
      const ids = journalDocs.map((d) => d.id);
      if (ids.length) {
        await c.query("insert into _export_ids (firestore_id) select unnest($1::text[])", [ids]);
      }

      // Absent from the export AND edited in the new app: the old app deleted
      // it but the new app has since changed it. Keep the edit, report it.
      const conflicts = await c.query(
        `select firestore_id from public.journals j
          where j.firestore_id is not null
            and not exists (select 1 from _export_ids e where e.firestore_id = j.firestore_id)
            and j.updated_at > j.migrated_updated_at`,
      );
      for (const r of conflicts.rows) {
        report.anomaly(
          "delete_vs_new_app_edit",
          `${r.firestore_id}: deleted in old app but edited in new app — KEPT`,
          { firestore_id: r.firestore_id },
        );
      }

      // Untouched since import (updated_at = migrated_updated_at) -> safe to
      // propagate the old-app delete. Rows with firestore_id IS NULL are
      // new-app journals and are never considered.
      const del = await c.query(
        `delete from public.journals j
          where j.firestore_id is not null
            and not exists (select 1 from _export_ids e where e.firestore_id = j.firestore_id)
            and j.updated_at = j.migrated_updated_at`,
      );
      report.count("journal_deleted_from_old_app", del.rowCount ?? 0);
      await c.query("commit");
    } catch (e) {
      const c2 = c;
      await c2.query("rollback").catch(() => {});
      throw e;
    } finally {
      c.release();
    }
  }

  await pool.end();
  report.write();

  if (report.get("anomaly:journal_unmapped_owner") > 0) {
    fail("journals had unmapped owners — import_users must run successfully first");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
