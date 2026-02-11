---
tc-id: TC-001
title: Scan Clean Repo (No Secrets)
---

## Objective

Verify that scanning a clean repository returns exit code 0 and reports no tokens found.

## Steps

1. Remove files with secrets so the repo is clean
   ```bash
   git rm -q config.env test/mock_tokens.json
   git commit -q -m "Remove files with secrets for clean test"
   ```

2. Run scan on clean repository
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

4. Verify output indicates clean
   ```bash
   echo "$OUTPUT" | grep -qi "no tokens\|clean" && echo "PASS: Clean message found" || echo "FAIL: No clean message"
   ```

## Expected

- Exit code: 0
- Output contains "No tokens" or "clean" indication
