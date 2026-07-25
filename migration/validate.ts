// Post-import validation. Exits non-zero on any discrepancy, so sync.sh fails
// loudly rather than reporting a green run over silently corrupt data.
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/validate.ts
//
// Four independent checks, per the plan:
//   (a) row counts       export lines vs migrated rows
//   (b) per-user counts   export grouped by userId vs SQL grouped by firebase_uid
//   (c) field-level       recompute the transform from `raw` on a random sample
//                         and diff against the stored columns
//   (d) orphans           rows that reference nothing
//
// (c) is the one that catches real bugs: (a) and (b) only prove rows arrived,
// not that their contents are right.

import { readFileSync } from "node:fs";
import { join } from "node:path";
import pg from "pg";
import { assertPoolerUrl, exportsDir, fail, requireEnv, runTs } from "./lib/env.ts";
import { Report } from "./lib/report.ts";
import { type ExportedDoc, transformJournal } from "./lib/transform.ts";

const SAMPLE_SIZE = 25;

function readJsonl(path: string): ExportedDoc[] {
  return readFileSync(path, "utf8")
    .split("\n")
    .filter((l) => l.trim() !== "")
    .map((l) => JSON.parse(l));
}

/** Deterministic sample: same export always checks the same rows, so a failure
 *  is reproducible instead of appearing and vanishing between runs. */
function sample<T>(items: T[], n: number): T[] {
  if (items.length <= n) return items;
  const step = items.length / n;
  return Array.from({ length: n }, (_, i) => items[Math.floor(i * step)]);
}

/**
 * Order-insensitive deep comparison.
 *
 * Postgres `jsonb` does NOT preserve object key order -- it normalises keys by
 * length then bytewise. So a jsonb round-trip of {createdAt, emotions, …} comes
 * back as {tmdbId, userId, emotions, …} with identical content. Comparing
 * JSON.stringify output directly reports every single jsonb column as
 * mismatched. Array order IS preserved and IS significant, so arrays are
 * compared positionally.
 */
function canonical(v: unknown): unknown {
  if (Array.isArray(v)) return v.map(canonical);
  if (v && typeof v === "object") {
    return Object.fromEntries(
      Object.entries(v as Record<string, unknown>)
        .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
        .map(([k, val]) => [k, canonical(val)]),
    );
  }
  return v;
}

function eq(a: unknown, b: unknown): boolean {
  return JSON.stringify(canonical(a)) === JSON.stringify(canonical(b));
}

async function main(): Promise<void> {
  const ts = runTs();
  const report = new Report("validate");
  const dir = exportsDir(ts);

  const userDocs = readJsonl(join(dir, "users.jsonl"));
  const journalDocs = readJsonl(join(dir, "journals.jsonl"));

  const dbUrl = requireEnv("SUPABASE_DB_URL");
  assertPoolerUrl(dbUrl);
  const pool = new pg.Pool({ connectionString: dbUrl, max: 2 });
  const c = await pool.connect();
  let failures = 0;
  const fails = (msg: string, extra: Record<string, unknown> = {}) => {
    failures++;
    report.anomaly("VALIDATION_FAILED", msg, extra);
    console.error(`  FAIL  ${msg}`);
  };

  try {
    // ---- tombstones are legitimate absences, so exclude them from every count
    const tombJournals = new Set(
      (await c.query("select firestore_id from public.sync_tombstones where kind='journal'")).rows.map(
        (r) => r.firestore_id,
      ),
    );
    const tombUsers = new Set(
      (await c.query("select firestore_id from public.sync_tombstones where kind='user'")).rows.map(
        (r) => r.firestore_id,
      ),
    );

    // ---------------------------------------------------------- (a) counts
    const expectedJournals = journalDocs.filter(
      (d) => !tombJournals.has(d.id) && !tombUsers.has(String(d.data.userId)) && d.data.userId,
    ).length;
    const actualJournals = Number(
      (await c.query("select count(*) n from public.journals where firestore_id is not null")).rows[0].n,
    );
    report.count("expected_migrated_journals", expectedJournals);
    report.count("actual_migrated_journals", actualJournals);
    if (expectedJournals !== actualJournals) {
      fails(`(a) journal count mismatch: export expects ${expectedJournals}, db has ${actualJournals}`);
    }

    const expectedProfiles = userDocs.filter((d) => !tombUsers.has(d.id)).length;
    const actualProfiles = Number(
      (await c.query("select count(*) n from public.profiles where firebase_uid is not null")).rows[0].n,
    );
    report.count("expected_migrated_profiles", expectedProfiles);
    report.count("actual_migrated_profiles", actualProfiles);
    if (expectedProfiles !== actualProfiles) {
      fails(`(a) profile count mismatch: export expects ${expectedProfiles}, db has ${actualProfiles}`);
    }

    // ------------------------------------------------- (b) per-user counts
    const byUser = new Map<string, number>();
    for (const d of journalDocs) {
      const u = d.data.userId;
      if (typeof u !== "string" || tombUsers.has(u) || tombJournals.has(d.id)) continue;
      byUser.set(u, (byUser.get(u) ?? 0) + 1);
    }
    const dbByUser = new Map<string, number>();
    for (const r of (
      await c.query(
        `select p.firebase_uid, count(j.id) n
           from public.profiles p
           left join public.journals j on j.user_id = p.id and j.firestore_id is not null
          where p.firebase_uid is not null
          group by p.firebase_uid`,
      )
    ).rows) {
      dbByUser.set(r.firebase_uid, Number(r.n));
    }
    let userMismatches = 0;
    for (const [uid, n] of byUser) {
      const got = dbByUser.get(uid) ?? 0;
      if (got !== n) {
        userMismatches++;
        fails(`(b) user ${uid}: export has ${n} journals, db has ${got}`, { firebase_uid: uid });
      }
    }
    report.count("per_user_checked", byUser.size);
    report.count("per_user_mismatches", userMismatches);

    // ------------------------------------------------ (c) field-level diff
    const throwaway = new Report("validate-recompute"); // absorbs transform anomalies
    const picked = sample(
      journalDocs.filter((d) => !tombJournals.has(d.id) && d.data.userId),
      SAMPLE_SIZE,
    );
    let fieldMismatches = 0;
    for (const doc of picked) {
      const expect = transformJournal(doc, throwaway);
      if (!expect) continue;
      const { rows } = await c.query(
        `select tmdb_id, movie_title, movie_poster, emotions, selected_scenes,
                selected_refs, thoughts,
                to_char(created_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') created_at,
                to_char(updated_at at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') updated_at,
                raw
           from public.journals where firestore_id = $1`,
        [doc.id],
      );
      if (!rows.length) {
        fails(`(c) ${doc.id}: sampled journal missing from db`, { firestore_id: doc.id });
        continue;
      }
      const got = rows[0];
      const checks: Array<[string, unknown, unknown]> = [
        ["tmdb_id", expect.tmdb_id, got.tmdb_id],
        ["movie_title", expect.movie_title, got.movie_title],
        ["movie_poster", expect.movie_poster, got.movie_poster],
        ["emotions", expect.emotions, got.emotions],
        ["selected_scenes", expect.selected_scenes, got.selected_scenes],
        ["selected_refs", expect.selected_refs, got.selected_refs],
        ["thoughts", expect.thoughts, got.thoughts],
        ["created_at", expect.created_at, got.created_at],
        ["updated_at", expect.updated_at, got.updated_at],
        ["raw", expect.raw, got.raw],
      ];
      for (const [field, want, have] of checks) {
        if (!eq(want, have)) {
          fieldMismatches++;
          // Never print `thoughts` or `raw` contents -- this is user-written
          // personal material and reports are kept on disk.
          const safe = field === "thoughts" || field === "raw" ? "<redacted>" : JSON.stringify(want);
          fails(`(c) ${doc.id}.${field} differs (expected ${safe})`, { firestore_id: doc.id, field });
        }
      }
    }
    report.count("field_sampled", picked.length);
    report.count("field_mismatches", fieldMismatches);

    // ------------------------------------------------------- (d) orphans
    const orphanJournals = Number(
      (
        await c.query(
          `select count(*) n from public.journals j
            where not exists (select 1 from auth.users u where u.id = j.user_id)`,
        )
      ).rows[0].n,
    );
    if (orphanJournals) fails(`(d) ${orphanJournals} journals reference a missing auth.users row`);

    const orphanProfiles = Number(
      (
        await c.query(
          `select count(*) n from public.profiles p
            where not exists (select 1 from auth.users u where u.id = p.id)`,
        )
      ).rows[0].n,
    );
    if (orphanProfiles) fails(`(d) ${orphanProfiles} profiles reference a missing auth.users row`);

    const unmappedJournals = Number(
      (
        await c.query(
          `select count(*) n from public.journals j
            where j.firestore_id is not null
              and not exists (select 1 from public.profiles p where p.id = j.user_id)`,
        )
      ).rows[0].n,
    );
    if (unmappedJournals) fails(`(d) ${unmappedJournals} migrated journals have no profile row`);

    report.count("orphan_journals", orphanJournals);
    report.count("orphan_profiles", orphanProfiles);
    report.count("journals_without_profile", unmappedJournals);
  } finally {
    c.release();
    await pool.end();
  }

  report.count("failures", failures);
  report.write();

  if (failures) fail(`validation FAILED with ${failures} discrepancy/discrepancies`);
  console.log("\n  validation PASSED");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
