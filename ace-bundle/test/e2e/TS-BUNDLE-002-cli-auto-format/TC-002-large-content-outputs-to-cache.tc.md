---
tc-id: TC-002
title: Large and At-Threshold Content Outputs to Cache
---

## Objective

Verify that content at or over 500 lines is saved to cache and a file path is returned, both for a large preset (600 lines) and an at-threshold preset (~500 lines).

## Steps

1. Load large preset and verify cache output
   ```bash
   OUTPUT=$(ace-bundle large-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
   echo "$OUTPUT" | grep -q ".cache/ace-bundle" && echo "PASS: Cache path in output" || echo "FAIL: No cache path"
   ```

2. Load at-threshold preset and verify cache output
   ```bash
   OUTPUT=$(ace-bundle at-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: At threshold goes to cache" || echo "FAIL: Expected cache output"
   ```

## Expected

- Both presets exit 0
- Large preset (600 lines) output contains "Bundle saved", "output file:", and ".cache/ace-bundle"
- At-threshold preset (~500 lines) also goes to cache
