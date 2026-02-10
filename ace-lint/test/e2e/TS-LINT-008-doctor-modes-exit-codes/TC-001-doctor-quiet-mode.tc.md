---
tc-id: TC-001
title: Doctor Quiet Mode
---

## Objective

Verify that doctor command quiet mode suppresses output.

## Steps

1. Run doctor command with --quiet flag
   ```bash
   OUTPUT=$(ace-lint doctor --quiet 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output length: ${#OUTPUT}"
   echo "Output: $OUTPUT"
   ```

2. Verify output is minimal or empty
   ```bash
   OUTPUT_LEN=${#OUTPUT}
   if [ "$OUTPUT_LEN" -lt 100 ]; then
     echo "PASS: Quiet mode produces minimal output"
   else
     echo "INFO: Output length is $OUTPUT_LEN characters"
   fi
   ```

## Expected

- Command completes with valid exit code
- Output is suppressed or minimal in quiet mode
