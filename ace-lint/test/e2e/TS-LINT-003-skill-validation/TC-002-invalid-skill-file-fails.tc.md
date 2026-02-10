---
tc-id: TC-002
title: Invalid Skill File Fails
---

## Objective

Verify that ace-lint detects SKILL.md with missing required field, reports validation failure, and identifies the missing 'source' field.

## Steps

1. Lint the invalid SKILL.md file
   ```bash
   OUTPUT=$(ace-lint lint invalid/SKILL.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify output shows file failed validation
   ```bash
   echo "$OUTPUT" | grep -qE "(failed|error)" && echo "PASS: Output indicates failure" || echo "FAIL: Output should indicate failure"
   ```

3. Verify report mentions missing 'source' field
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   grep -qi "source" "${REPORT_DIR}/pending.md" && echo "PASS: Report mentions 'source' field" || echo "FAIL: Report should mention missing 'source' field"
   ```

## Expected

- Output shows "N failed" indicating validation failure
- pending.md report contains error about missing "source" field
- File is identified as having validation errors
