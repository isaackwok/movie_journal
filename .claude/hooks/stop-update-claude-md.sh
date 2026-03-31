#!/bin/bash
# Stop hook: reminds to update CLAUDE.md when code files change without
# a corresponding CLAUDE.md update.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
cd "${CWD:-.}" 2>/dev/null || exit 0

# Collect changed code files (staged + unstaged + untracked),
# excluding CLAUDE.md and .claude/ config directory
code_changes=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep -v '^CLAUDE\.md$' \
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

if [[ -n "$code_changes" && -z "$claude_md_changed" ]]; then
  echo "Code files were modified but CLAUDE.md has not been updated." >&2
  echo "Please update CLAUDE.md to reflect these changes:" >&2
  echo "$code_changes" | sed 's/^/  /' >&2
  exit 2
fi

exit 0
