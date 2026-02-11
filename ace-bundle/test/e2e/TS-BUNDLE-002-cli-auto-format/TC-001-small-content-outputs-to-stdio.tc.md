---
tc-id: TC-001
title: Small and Below-Threshold Content Outputs to Stdio
---

## Objective

Verify that content under 500 lines is output directly to stdout, both for a small preset and a below-threshold preset (~100 lines).

## Steps

1. Load small preset and verify stdio output
   ```bash
   OUTPUT=$(ace-bundle small-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "# Small Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
   ! echo "$OUTPUT" | grep -q "output file:" && echo "PASS: No file reference" || echo "FAIL: Unexpected file reference"
   ```

2. Load below-threshold preset and verify stdio output
   ```bash
   OUTPUT=$(ace-bundle below-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Below threshold goes to stdio" || echo "FAIL: Unexpected cache"
   echo "$OUTPUT" | grep -q "# Test Content" && echo "PASS: Content in stdout" || echo "FAIL: Content not found"
   ```

## Expected

- Both presets exit 0
- Small preset output contains "# Small Test Content" directly in stdout
- Small preset output does NOT contain "Bundle saved" or "output file:"
- Below-threshold preset (~100 lines) also goes to stdio
