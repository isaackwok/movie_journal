// Export the `users` and `journals` Firestore collections to JSONL.
//
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/export_firestore.ts
//
// Output per collection: one {id, createTime, updateTime, data} object per
// line, plus a row count and sha256. Document metadata times are carried
// because they are the fallback when a doc's own createdAt/updatedAt field is
// missing or unparseable.
//
// Paging uses orderBy(documentId()) + startAfter rather than offset: offset
// still reads and bills for every skipped document, and gives no stable
// ordering guarantee across pages.

import { createWriteStream } from "node:fs";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import admin from "firebase-admin";
import { dataDir, exportsDir, requireEnv, runTs, fail } from "./lib/env.ts";
import { Report } from "./lib/report.ts";

const PAGE = 500;
const COLLECTIONS = ["users", "journals"] as const;

function initFirebase(): admin.firestore.Firestore {
  const projectId = requireEnv("FIREBASE_PROJECT_ID");
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credPath) {
    fail(
      "GOOGLE_APPLICATION_CREDENTIALS is not set.\n" +
        '  It lives in $MIGRATION_DATA_DIR/.env; run with --env-file, or\n' +
        '  source "$MIGRATION_DATA_DIR/activate.sh" for an ad-hoc shell.',
    );
  }
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(readFileSync(credPath, "utf8"))),
    projectId,
  });
  return admin.firestore();
}

/**
 * Firestore Timestamps become zone-aware ISO-UTC strings; nested maps/arrays
 * are walked. Everything else passes through untouched so `data` stays a
 * faithful copy of the document -- it is stored verbatim in journals.raw and
 * is the zero-data-loss backstop.
 */
function serialize(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (value instanceof admin.firestore.Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (value instanceof admin.firestore.GeoPoint) {
    return { latitude: value.latitude, longitude: value.longitude };
  }
  if (value instanceof admin.firestore.DocumentReference) return value.path;
  if (Buffer.isBuffer(value)) return value.toString("base64");
  if (Array.isArray(value)) return value.map(serialize);
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) out[k] = serialize(v);
    return out;
  }
  return value;
}

async function exportCollection(
  db: admin.firestore.Firestore,
  name: string,
  outDir: string,
  report: Report,
): Promise<void> {
  const outPath = join(outDir, `${name}.jsonl`);
  const stream = createWriteStream(outPath, { encoding: "utf8" });
  const hash = createHash("sha256");
  let cursor: admin.firestore.QueryDocumentSnapshot | undefined;
  let total = 0;

  for (;;) {
    let q = db
      .collection(name)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE);
    if (cursor) q = q.startAfter(cursor);

    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      const line =
        JSON.stringify({
          id: doc.id,
          createTime: doc.createTime?.toDate().toISOString() ?? null,
          updateTime: doc.updateTime?.toDate().toISOString() ?? null,
          data: serialize(doc.data()),
        }) + "\n";
      stream.write(line);
      hash.update(line);
      total++;
    }

    cursor = snap.docs[snap.docs.length - 1];
    process.stdout.write(`\r  ${name}: ${total}`);
    if (snap.size < PAGE) break;
  }

  await new Promise<void>((res, rej) => {
    stream.end(() => res());
    stream.on("error", rej);
  });

  const sha = hash.digest("hex");
  const { writeFileSync } = await import("node:fs");
  writeFileSync(`${outPath}.sha256`, `${sha}  ${name}.jsonl\n`);

  process.stdout.write("\r");
  console.log(`  ${name.padEnd(10)} ${String(total).padStart(6)} docs  sha256=${sha.slice(0, 16)}…`);
  report.count(`${name}_docs`, total);
}

async function main(): Promise<void> {
  const ts = runTs();
  const report = new Report("export_firestore");
  const outDir = exportsDir(ts);
  console.log(`exporting Firestore -> ${outDir}`);

  const db = initFirebase();
  for (const c of COLLECTIONS) await exportCollection(db, c, outDir, report);

  // A zero-row export would make the deletion-propagation pass in import_data
  // interpret every existing row as "deleted in the old app" and wipe the
  // table. Refuse rather than hand that downstream.
  if (report.get("journals_docs") === 0 && report.get("users_docs") === 0) {
    report.write();
    fail("export produced zero documents in BOTH collections — refusing to continue");
  }

  report.write();
  console.log(`\nRUN_TS=${ts}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
