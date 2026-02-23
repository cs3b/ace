---
tc-id: TC-001
title: Single Model Review Execution
---

## Objective

Verify that ace-review executes with a single model, produces a session directory with review output, and completes within reasonable time bounds.

## Steps

1. Run ace-review with single model preset
   ```bash
   SESSION_DIR="$PWD/session-tc001"

   START_TIME=$(date +%s)
   OUTPUT=$(ace-review \
     --preset single \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?
   END_TIME=$(date +%s)
   DURATION=$((END_TIME - START_TIME))

   echo "Exit code: $EXIT_CODE"
   echo "Duration: ${DURATION}s"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify execution results
   ```bash
   SESSION_DIR="$PWD/session-tc001"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   REVIEW_FILE=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | head -1)
   if [ -n "$REVIEW_FILE" ]; then
     echo "PASS: Review file created: $(basename $REVIEW_FILE)"
     LINES=$(wc -l < "$REVIEW_FILE")
     [ "$LINES" -gt 3 ] && echo "PASS: Review has content ($LINES lines)" || echo "FAIL: Review too short"
   else
     echo "FAIL: No review file"
   fi

   [ "$DURATION" -lt 60 ] && echo "PASS: Completed in ${DURATION}s (< 60s)" || echo "FAIL: Took too long: ${DURATION}s"
   ```

## Expected

- Exit code: 0
- Session directory created with review markdown file
- Review file has meaningful content (> 3 lines)
- Execution completes within 60 seconds
