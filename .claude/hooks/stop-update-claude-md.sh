#!/bin/bash
# Stop hook: nudges doc updates only for SIGNIFICANT, doc-worthy code changes.
#
# Philosophy: not every code change deserves a doc edit. Forcing CLAUDE.md /
# README.md updates for trivial fixes pads the docs with noise and breeds rot —
# the opposite of the goal. So this hook only blocks when a change is
# substantial enough that the docs likely need to reflect it, and it asks for
# each file only when that file is actually relevant:
#
#   CLAUDE.md (architecture / internals) — required when a lib/ change is
#     "significant": a new .dart file (new feature/component/controller),
#     a large diff (>= DOC_HOOK_MIN_LINES, default 80), or a new dependency.
#
#   README.md (user-facing) — required ONLY when something genuinely
#     user-facing is introduced: a brand-new feature directory under
#     lib/features/, or a pubspec.yaml change (new integration/dependency).
#     Internal tweaks to existing screens/widgets never demand a README edit.
#
# Small/medium edits to existing files, test-only changes, and generated files
# let Stop proceed silently. Tune the line threshold with DOC_HOOK_MIN_LINES.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
cd "${CWD:-.}" 2>/dev/null || exit 0

MIN_LINES="${DOC_HOOK_MIN_LINES:-80}"

# --- Relevant source files: lib/ Dart only, excluding generated code ---
lib_changes=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep -E '^lib/.*\.dart$' \
    | grep -v '\.g\.dart$' \
    | grep -v '^lib/firebase_options\.dart$' \
    | sort -u
)

# Did pubspec.yaml change? (dependency = documented in CLAUDE.md + user-facing)
pubspec_changed=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
  } | grep -E '^pubspec\.yaml$'
)

# Nothing doc-worthy in play → let Stop proceed.
[[ -z "$lib_changes" && -z "$pubspec_changed" ]] && exit 0

# --- New lib/ Dart files (added to index or untracked) ---
new_lib_files=$(
  {
    git diff --cached --name-only --diff-filter=A 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep -E '^lib/.*\.dart$' \
    | grep -v '\.g\.dart$' \
    | sort -u
)

# --- Total lines touched across lib/ Dart files (added + removed) ---
changed_lines=$(
  {
    git diff --cached --numstat 2>/dev/null
    git diff --numstat 2>/dev/null
  } | awk '$3 ~ /^lib\/.*\.dart$/ && $3 !~ /\.g\.dart$/ { a += $1; r += $2 } END { print a + r + 0 }'
)
changed_lines=${changed_lines:-0}

# --- Significance gate (drives the CLAUDE.md requirement) ---
significant=false
[[ -n "$new_lib_files" ]] && significant=true
[[ -n "$pubspec_changed" ]] && significant=true
[[ "$changed_lines" -ge "$MIN_LINES" ]] && significant=true

$significant || exit 0

# --- README relevance: a NEW feature dir, or a pubspec change ---
readme_required=false
[[ -n "$pubspec_changed" ]] && readme_required=true
for f in $new_lib_files; do
  feat=$(printf '%s\n' "$f" | sed -nE 's#^(lib/features/[^/]+)/.*#\1#p')
  # The feature dir is new if it doesn't exist in HEAD's tree.
  if [[ -n "$feat" ]] && [[ -z "$(git ls-tree HEAD -- "$feat" 2>/dev/null)" ]]; then
    readme_required=true
    break
  fi
done

# --- Which docs are still missing? ---
docs_touched=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
  }
)
claude_md_changed=$(printf '%s\n' "$docs_touched" | grep '^CLAUDE\.md$')
readme_md_changed=$(printf '%s\n' "$docs_touched" | grep '^README\.md$')

missing=""
[[ -z "$claude_md_changed" ]] && missing="CLAUDE.md"
if $readme_required && [[ -z "$readme_md_changed" ]]; then
  missing="${missing:+$missing and }README.md"
fi

# Everything relevant is already documented → proceed.
[[ -z "$missing" ]] && exit 0

echo "Significant code changes detected, but $missing has not been updated." >&2
echo "Please update $missing to reflect these changes:" >&2
[[ -n "$lib_changes" ]] && printf '%s\n' "$lib_changes" | sed 's/^/  /' >&2
[[ -n "$pubspec_changed" ]] && echo "  pubspec.yaml" >&2
exit 2
