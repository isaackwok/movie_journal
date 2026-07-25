// Path and credential resolution for every migration script.
//
// Hard rule from the plan: data and secrets live OUTSIDE this repo, under
// $MIGRATION_DATA_DIR. movie_journal is a PUBLIC GitHub repo, so a script that
// silently falls back to a repo-relative path is a data-leak bug, not a
// convenience. Nothing here defaults to a repo path -- an unset var aborts.
//
// Also deliberately absent: any dotenv call. `dotenv.config()` resolves .env
// from process.cwd(), so running from the repo root would quietly load the
// *app's* .env (TMDB keys) and fail later with a confusing undefined-env error.
// Scripts are invoked as:
//   node --env-file="$MIGRATION_DATA_DIR/.env" migration/<script>.ts

import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";

export function fail(msg: string): never {
  console.error(`\nERROR: ${msg}\n`);
  process.exit(1);
}

/** Absolute path to the out-of-repo data directory. Aborts if unset/missing. */
export function dataDir(): string {
  const d = process.env.MIGRATION_DATA_DIR;
  if (!d) {
    fail(
      "MIGRATION_DATA_DIR is not set.\n" +
        '  Run:  export MIGRATION_DATA_DIR="$HOME/development/movie-journal-migration"\n' +
        "  (it is exported from ~/.zshrc for interactive shells, but NOT for\n" +
        "   non-interactive ones -- cron and CI must set it themselves)",
    );
  }
  if (!d.startsWith("/")) fail(`MIGRATION_DATA_DIR must be absolute, got: ${d}`);
  if (!existsSync(d)) fail(`MIGRATION_DATA_DIR does not exist: ${d}`);
  return d;
}

export function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) {
    fail(
      `${name} is not set.\n` +
        '  Scripts must be run as: node --env-file="$MIGRATION_DATA_DIR/.env" migration/<script>.ts',
    );
  }
  return v;
}

/**
 * Timestamp identifying one run of the chain. Every script in a single
 * sync.sh invocation shares it (passed via RUN_TS) so exports, reports and
 * logs from one run land together and can be correlated after the fact.
 */
export function runTs(): string {
  return process.env.RUN_TS ?? new Date().toISOString().replace(/[:.]/g, "-");
}

export function exportsDir(ts = runTs()): string {
  const d = join(dataDir(), "exports", ts);
  mkdirSync(d, { recursive: true });
  return d;
}

export function reportsDir(): string {
  const d = join(dataDir(), "reports");
  mkdirSync(d, { recursive: true });
  return d;
}

/** Service-role/secret key. Accepts either name -- the project may hold a new
 *  `sb_secret_...` key or a legacy service-role JWT, and the plan says to name
 *  the variable after whichever you actually have. */
export function supabaseSecretKey(): string {
  const v = process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!v) fail("neither SUPABASE_SECRET_KEY nor SUPABASE_SERVICE_ROLE_KEY is set");
  return v;
}

/** Guard against pointing a destructive run at the wrong database. */
export function assertPoolerUrl(dbUrl: string): void {
  let u: URL;
  try {
    u = new URL(dbUrl);
  } catch {
    fail("SUPABASE_DB_URL is not a valid URL");
  }
  if (u.port === "6543") {
    fail(
      "SUPABASE_DB_URL uses port 6543 (transaction pooler).\n" +
        "  import_data needs SESSION mode (port 5432): transaction mode does not\n" +
        "  support prepared statements and routes successive statements to different\n" +
        "  backends, which breaks the session-scoped temp table used for deletion\n" +
        "  propagation. Deletions would silently stop syncing.",
    );
  }
}
