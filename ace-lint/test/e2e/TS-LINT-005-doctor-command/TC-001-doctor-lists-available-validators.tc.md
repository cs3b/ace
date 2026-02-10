---
tc-id: TC-001
title: Doctor Lists Available Validators
---

## Objective

Verify that doctor command shows available validators.

## Steps

1. Run doctor command without any config
   ```bash
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify validators are listed
   ```bash
   echo "$OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators mentioned" || echo "FAIL: No validators found in output"
   ```

## Expected

- Exit code: 0 or 1 (depending on validator availability)
- Output mentions validators (standardrb, rubocop, or generic "validator")
