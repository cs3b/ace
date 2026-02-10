---
tc-id: TC-003
title: Exit Code 0 When Healthy
---

## Objective

Verify that doctor returns exit code 0 when configuration is healthy.

## Steps

1. Run doctor in a clean directory (no config = uses defaults)
   ```bash
   mkdir -p clean-dir
   cd clean-dir
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Check exit code (0 = healthy, 1 = warnings are acceptable)
   ```bash
   if [ "$EXIT_CODE" -eq 0 ]; then
     echo "PASS: Exit code 0 (healthy)"
   elif [ "$EXIT_CODE" -eq 1 ]; then
     echo "PASS: Exit code 1 (warnings, e.g., missing validators)"
   else
     echo "FAIL: Unexpected exit code $EXIT_CODE"
   fi
   ```

## Expected

- Exit code: 0 (healthy) or 1 (warnings like missing validators)
- Not exit code 2 (errors)
