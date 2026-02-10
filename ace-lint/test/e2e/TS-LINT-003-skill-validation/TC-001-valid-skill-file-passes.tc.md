---
tc-id: TC-001
title: Valid Skill File Passes
---

## Objective

Verify that ace-lint detects SKILL.md, validates it against the skill schema, and exits 0 when valid.

## Steps

1. Lint the valid SKILL.md file
   ```bash
   OUTPUT=$(ace-lint lint SKILL.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   test "$EXIT_CODE" -eq 0 && echo "PASS: Exit code is 0" || echo "FAIL: Exit code is $EXIT_CODE"
   ```

3. Verify output indicates pass
   ```bash
   echo "$OUTPUT" | grep -qE "(passed|ok|✓)" && echo "PASS: Output indicates success" || echo "FAIL: No success indicator in output"
   ```

## Expected

- Exit code: 0
- Output shows file passed validation
- No validation errors reported
