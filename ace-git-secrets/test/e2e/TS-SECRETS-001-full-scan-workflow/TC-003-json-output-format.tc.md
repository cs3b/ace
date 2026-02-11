---
tc-id: TC-003
title: JSON Output Format
---

## Objective

Verify that JSON report format generates a valid report file with expected structure.

## Steps

1. Run scan with JSON report format
   ```bash
   OUTPUT=$(ace-git-secrets scan --format json 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify report file is saved
   ```bash
   echo "$OUTPUT" | grep -qE "Report saved:.*\.json" && echo "PASS: Report saved message" || echo "FAIL: No report saved message"
   ```

3. Find and verify JSON report structure
   ```bash
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "PASS: Report file exists: $REPORT_FILE"
     cat "$REPORT_FILE" | jq . > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
     cat "$REPORT_FILE" | jq -e '.tokens' > /dev/null && echo "PASS: Has tokens key" || echo "FAIL: Missing tokens key"
     cat "$REPORT_FILE" | jq -e '.scan_metadata' > /dev/null && echo "PASS: Has scan_metadata" || echo "FAIL: Missing scan_metadata"
   else
     echo "FAIL: Report file not found"
   fi
   ```

## Expected

- Report saved to .cache/ace-git-secrets/sessions/
- Valid JSON structure with tokens and scan_metadata keys
