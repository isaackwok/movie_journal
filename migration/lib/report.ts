// Run reporting. The plan requires every script to write
// $MIGRATION_DATA_DIR/reports/<timestamp>.json with counts, skips, conflicts,
// dedupes and anomalies.
//
// This matters more than usual here: the delta-sync runs unattended ~28 times.
// Anything it decides silently -- a timestamp that fell back to doc metadata, a
// username collision renamed to _2, a journal kept because the new app edited
// it after an old-app delete -- is invisible unless it lands in a report.

import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { reportsDir, runTs } from "./env.ts";

export type Anomaly = {
  kind: string;
  detail: string;
  [k: string]: unknown;
};

export class Report {
  readonly script: string;
  readonly ts: string;
  private counts: Record<string, number> = {};
  private anomalies: Anomaly[] = [];
  private started = Date.now();

  constructor(script: string) {
    this.script = script;
    this.ts = runTs();
  }

  count(key: string, n = 1): void {
    this.counts[key] = (this.counts[key] ?? 0) + n;
  }

  /** Record something a human may need to act on. Always also increments a
   *  counter keyed by kind, so totals and details never drift apart. */
  anomaly(kind: string, detail: string, extra: Record<string, unknown> = {}): void {
    this.anomalies.push({ kind, detail, ...extra });
    this.count(`anomaly:${kind}`);
  }

  get(key: string): number {
    return this.counts[key] ?? 0;
  }

  anomalyCount(): number {
    return this.anomalies.length;
  }

  /** Write the report and echo a compact summary. Returns the path. */
  write(): string {
    const path = join(reportsDir(), `${this.ts}-${this.script}.json`);
    const body = {
      script: this.script,
      runTs: this.ts,
      finishedAt: new Date().toISOString(),
      durationMs: Date.now() - this.started,
      counts: this.counts,
      anomalyCount: this.anomalies.length,
      anomalies: this.anomalies,
    };
    writeFileSync(path, JSON.stringify(body, null, 2));

    console.log(`\n--- ${this.script} ---`);
    for (const [k, v] of Object.entries(this.counts).sort()) {
      console.log(`  ${k.padEnd(38)} ${v}`);
    }
    if (this.anomalies.length) {
      // Group so a thousand instances of one problem read as one line.
      const byKind: Record<string, number> = {};
      for (const a of this.anomalies) byKind[a.kind] = (byKind[a.kind] ?? 0) + 1;
      console.log(`  ANOMALIES (${this.anomalies.length}):`);
      for (const [k, v] of Object.entries(byKind).sort()) {
        console.log(`    ${k.padEnd(36)} ${v}`);
      }
    }
    console.log(`  report -> ${path}`);
    return path;
  }
}
