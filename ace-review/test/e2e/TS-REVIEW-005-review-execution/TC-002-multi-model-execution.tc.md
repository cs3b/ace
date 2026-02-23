---
tc-id: TC-002
title: Multi-Model Review Execution
---

## Objective

Verify that ace-review can execute with multiple models via the models array preset format and produces review output.

## Steps

1. Run ace-review with multi-model preset
   ```bash
   SESSION_DIR="$PWD/session-tc002"

   OUTPUT=$(ace-review \
     --preset multi \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify multi-model execution
   ```bash
   SESSION_DIR="$PWD/session-tc002"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   REVIEW_COUNT=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | wc -l | tr -d ' ')
   echo "Review files found: $REVIEW_COUNT"
   [ "$REVIEW_COUNT" -ge 1 ] && echo "PASS: Review file(s) created" || echo "FAIL: No review files"

   echo "Session contents:"
   ls -la "$SESSION_DIR"
   ```

## Expected

- Exit code: 0
- Session directory created
- At least one review file created (may be multiple or consolidated)
