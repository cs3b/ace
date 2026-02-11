---
tc-id: TC-002
title: Scan File Includes Raw Values
---

## Objective

Verify that scan output files include the raw_value field needed for revocation workflow.

## Steps

1. Run scan with JSON output
   ```bash
   ace-git-secrets scan --format json 2>&1
   ```

2. Find the saved report file and verify raw_value presence
   ```bash
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "Report file: $REPORT_FILE"
   else
     echo "FAIL: Report file not found"
     exit 1
   fi
   ```

3. Verify tokens array has raw_value field
   ```bash
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   TOKEN_COUNT=$(cat "$REPORT_FILE" | jq '.tokens | length')
   if [ "$TOKEN_COUNT" -gt 0 ]; then
     HAS_RAW=$(cat "$REPORT_FILE" | jq '.tokens[0] | has("raw_value")')
     [ "$HAS_RAW" = "true" ] && echo "PASS: raw_value present" || echo "FAIL: raw_value missing"

     RAW_VALUE=$(cat "$REPORT_FILE" | jq -r '.tokens[0].raw_value')
     echo "$RAW_VALUE" | grep -q "ghp_" && echo "PASS: raw_value has ghp_ prefix" || echo "FAIL: Invalid raw_value"
   else
     echo "INFO: No tokens found in report"
   fi
   ```

## Expected

- Report file saved with valid JSON
- Tokens array contains raw_value field
- raw_value contains actual token value with ghp_ prefix
