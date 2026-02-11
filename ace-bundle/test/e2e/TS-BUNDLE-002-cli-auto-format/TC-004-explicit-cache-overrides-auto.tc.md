---
tc-id: TC-004
title: Explicit --output cache Overrides Auto
---

## Objective

Verify that `--output cache` forces small content to a cache file, overriding the auto-format threshold.

## Steps

1. Load small preset with explicit cache output
   ```bash
   OUTPUT=$(ace-bundle small-test --output cache 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
   ```

## Expected

- Exit code: 0
- Output contains "Bundle saved"
- Output contains "output file:"
