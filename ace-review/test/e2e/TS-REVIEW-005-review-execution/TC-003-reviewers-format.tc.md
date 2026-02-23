---
tc-id: TC-003
title: Reviewers Format Preset Execution
---

## Objective

Verify that the reviewers format (named reviewer objects with individual models) works correctly via CLI with real API calls.

## Steps

1. Run ace-review with reviewers-format preset
   ```bash
   SESSION_DIR="$PWD/session-tc003"

   OUTPUT=$(ace-review \
     --preset reviewers-test \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify results
   ```bash
   SESSION_DIR="$PWD/session-tc003"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   REVIEW_COUNT=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | wc -l | tr -d ' ')
   [ "$REVIEW_COUNT" -ge 1 ] && echo "PASS: Review file(s) created" || echo "FAIL: No review files"

   echo "Session contents:"
   ls -la "$SESSION_DIR"
   ```

## Expected

- Exit code: 0
- Reviewers format preset is parsed and executed
- Session directory with review output created
