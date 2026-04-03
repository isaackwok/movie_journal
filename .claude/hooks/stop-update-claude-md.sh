#!/bin/bash
# Stop hook: reminds to update CLAUDE.md and README.md when code files change
# without a corresponding documentation update.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
cd "${CWD:-.}" 2>/dev/null || exit 0

# Collect changed code files (staged + unstaged + untracked),
# excluding CLAUDE.md, README.md, and .claude/ config directory
code_changes=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep -v '^CLAUDE\.md$' \
    | grep -v '^README\.md$' \
    | grep -v '^\.claude/' \
    | grep -E '\.(dart|yaml|json)$' \
    | sort -u
)

# Check if CLAUDE.md was also modified
claude_md_changed=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
  } | grep '^CLAUDE\.md$'
)

# Check if README.md was also modified
readme_md_changed=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
  } | grep '^README\.md$'
)

if [[ -n "$code_changes" && ( -z "$claude_md_changed" || -z "$readme_md_changed" ) ]]; then
  missing=""
  [[ -z "$claude_md_changed" ]] && missing="CLAUDE.md"
  [[ -z "$readme_md_changed" ]] && missing="${missing:+$missing and }README.md"
  echo "Code files were modified but $missing has not been updated." >&2
  echo "Please update $missing to reflect these changes:" >&2
  echo "$code_changes" | sed 's/^/  /' >&2
  exit 2
fi

exit 0
