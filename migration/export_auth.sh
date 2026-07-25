#!/usr/bin/env bash
# Export Firebase Auth users -> $MIGRATION_DATA_DIR/exports/$RUN_TS/auth_users.json
#
# The export carries, per user: localId (= firebase uid), email, emailVerified,
# createdAt, and providerUserInfo[] where providerId is apple.com / google.com
# and rawId is the provider `sub`. That sub is what firebase_identity_map is
# keyed on, so this file is the source of truth for identity mapping.
#
# Run via sync.sh, or standalone:
#   RUN_TS=$(date -u +%Y-%m-%dT%H-%M-%SZ) migration/export_auth.sh

set -euo pipefail

: "${MIGRATION_DATA_DIR:?MIGRATION_DATA_DIR is not set — export it or run via sync.sh}"
: "${FIREBASE_PROJECT_ID:=the-movie-journal}"
RUN_TS="${RUN_TS:-$(date -u +%Y-%m-%dT%H-%M-%SZ)}"

OUT_DIR="$MIGRATION_DATA_DIR/exports/$RUN_TS"
OUT="$OUT_DIR/auth_users.json"
mkdir -p "$OUT_DIR"

echo "exporting Firebase Auth users (project: $FIREBASE_PROJECT_ID)"
firebase auth:export "$OUT" --format=json --project "$FIREBASE_PROJECT_ID"

# firebase auth:export exits 0 even when it writes nothing useful, so assert the
# shape before anything downstream trusts it as a source of truth.
if [ ! -s "$OUT" ]; then
  echo "ERROR: $OUT is empty or missing" >&2
  exit 1
fi

node -e '
const fs = require("fs");
const path = process.argv[1];
const d = JSON.parse(fs.readFileSync(path, "utf8"));
const users = d.users;
if (!Array.isArray(users)) { console.error("ERROR: no users[] array in export"); process.exit(1); }
const withEmail = users.filter(u => u.email).length;
const providers = {};
for (const u of users) for (const p of u.providerUserInfo ?? []) {
  providers[p.providerId] = (providers[p.providerId] ?? 0) + 1;
}
console.log(`  users:            ${users.length}`);
console.log(`  with email:       ${withEmail}`);
console.log(`  without email:    ${users.length - withEmail}`);
for (const [k, v] of Object.entries(providers).sort()) console.log(`  provider ${k.padEnd(14)} ${v}`);
if (users.length === 0) { console.error("ERROR: export contains zero users — refusing to proceed"); process.exit(1); }
' "$OUT"

shasum -a 256 "$OUT" | tee "$OUT.sha256"
echo "  -> $OUT"
