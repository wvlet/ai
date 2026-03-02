#!/bin/bash
# Stop hook: Verify the agent followed the verification workflow before finishing.
# This implements a self-feedback loop — if verification steps were skipped,
# the hook blocks Claude from stopping and tells it what to do.

INPUT=$(cat)

# CRITICAL: Prevent infinite loops. If this hook already fired once
# (stop_hook_active=true), let Claude stop regardless.
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Only check when there are actual code changes (not just research/questions)
if git diff --quiet HEAD 2>/dev/null; then
  exit 0  # No code changes, no verification needed
fi

# Check if sbt compile was run during this session by looking at
# recent build output. We check if .bsp or target dirs were touched recently.
CHANGED_SCALA=$(git diff --name-only HEAD | grep -c '\.scala$' || true)
if [ "$CHANGED_SCALA" -gt 0 ]; then
  echo "You modified ${CHANGED_SCALA} Scala file(s). Before finishing, run the verification workflow: ./sbt compile, then ./sbt <module>/test for affected modules, then ./sbt scalafmtAll. See the Verification Workflow section in CLAUDE.md." >&2
  exit 2
fi

exit 0
