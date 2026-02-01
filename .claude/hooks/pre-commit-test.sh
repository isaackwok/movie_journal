#!/bin/bash
# Pre-commit hook: runs flutter test before any git commit.
# Blocks the commit if tests fail.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only intercept git commit commands
if ! echo "$COMMAND" | grep -qE '\bgit\b.*\bcommit\b'; then
  exit 0
fi

# Run flutter test from the project directory
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
cd "${CWD:-.}" 2>/dev/null

echo "Running flutter test before commit..." >&2
OUTPUT=$(flutter test 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "$OUTPUT" >&2
  echo "Tests failed — commit blocked." >&2
  exit 2
fi

# Tests passed, allow the commit
exit 0
