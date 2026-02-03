#!/bin/bash
# Stop hook: ensures unit tests stay in sync with source code changes.
# Blocks if source files with existing tests were modified without
# updating those tests. Also mentions untested source files as an FYI.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
cd "${CWD:-.}" 2>/dev/null || exit 0

# Collect all changed dart files (staged + unstaged + untracked)
all_changed=$(
  {
    git diff --cached --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep '\.dart$' | sort -u
)

# Exit early if no dart files changed
[[ -z "$all_changed" ]] && exit 0

# Separate source files (lib/) from test files (test/)
source_changes=$(echo "$all_changed" | grep '^lib/' || true)
test_changes=$(echo "$all_changed" | grep '^test/' || true)

# Exit if no source files changed (only test files changed — that's fine)
[[ -z "$source_changes" ]] && exit 0

# Check each changed source file against its test counterpart
stale_tests=()
missing_tests=()

while IFS= read -r src_file; do
  [[ -z "$src_file" ]] && continue

  # Map lib/ path to test/ path: lib/x/y.dart → test/x/y_test.dart
  test_file=$(echo "$src_file" | sed 's|^lib/|test/|; s|\.dart$|_test.dart|')

  if [[ -f "$test_file" ]]; then
    # Existing test — was it also modified?
    if ! echo "$test_changes" | grep -qxF "$test_file"; then
      stale_tests+=("  $src_file  →  $test_file")
    fi
  else
    missing_tests+=("  $src_file")
  fi
done <<< "$source_changes"

# Only block when existing tests weren't updated alongside their source
if [[ ${#stale_tests[@]} -gt 0 ]]; then
  echo "Source files changed but their existing tests were not updated:"
  printf '%s\n' "${stale_tests[@]}"

  if [[ ${#missing_tests[@]} -gt 0 ]]; then
    echo ""
    echo "These source files have no test file yet (consider adding tests):"
    printf '%s\n' "${missing_tests[@]}"
  fi

  echo ""
  echo "Please add, remove, or adjust the corresponding unit tests."
  exit 2
fi

exit 0
