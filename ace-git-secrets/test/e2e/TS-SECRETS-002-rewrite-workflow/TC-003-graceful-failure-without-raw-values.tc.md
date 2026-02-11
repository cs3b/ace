---
tc-id: TC-003
title: Graceful Failure Without Raw Values
---

## Objective

Verify that revoke and rewrite-history commands fail gracefully with helpful errors when the scan file lacks raw_value fields.

## Steps

1. Move the broken-report fixture into the expected .cache location
   ```bash
   mkdir -p .cache/ace-git-secrets
   cp broken-report.json .cache/ace-git-secrets/broken-report.json
   ```

2. Attempt revoke with broken scan file (missing raw_value)
   ```bash
   OUTPUT=$(ace-git-secrets revoke --scan-file ".cache/ace-git-secrets/broken-report.json" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify revoke failed with helpful message
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Revoke failed as expected" || echo "FAIL: Expected failure"
   echo "$OUTPUT" | grep -qi "raw.value\|missing\|re-run\|scan" && echo "PASS: Helpful error message" || echo "FAIL: No helpful message"
   ```

4. Attempt rewrite-history with broken scan file
   ```bash
   OUTPUT2=$(ace-git-secrets rewrite-history --scan-file ".cache/ace-git-secrets/broken-report.json" --dry-run 2>&1)
   EXIT_CODE2=$?
   echo "Exit code: $EXIT_CODE2"
   echo "Output: $OUTPUT2"
   ```

5. Verify rewrite-history handles missing raw_value
   ```bash
   if [ "$EXIT_CODE2" -ne 0 ]; then
     echo "$OUTPUT2" | grep -qi "raw.value\|missing" && echo "PASS: Error mentions missing raw_value" || echo "INFO: Different error"
   else
     echo "INFO: Command succeeded (may have done fresh scan)"
   fi
   ```

## Expected

- Revoke: non-zero exit code with error mentioning missing raw_value
- Rewrite-history: either fails with helpful error or falls back to fresh scan
