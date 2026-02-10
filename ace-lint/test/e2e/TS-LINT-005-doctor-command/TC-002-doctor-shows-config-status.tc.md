---
tc-id: TC-002
title: Doctor Shows Config Status
---

## Objective

Verify that doctor command shows configuration information.

## Steps

1. Run doctor command in directory with config
   ```bash
   cd valid-config
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify config information is shown
   ```bash
   echo "$OUTPUT" | grep -qiE "config|configuration|\.ace" && echo "PASS: Config info present" || echo "FAIL: No config info"
   ```

## Expected

- Exit code: 0 or 1
- Output mentions configuration or config file
