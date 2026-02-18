---
tc-id: TC-001
title: Scan Detects Secrets in Git History After Removal
---

## Objective

Verify that scanning a repository after `git rm` still detects tokens in git history.
The `ace-git-secrets scan` uses `gitleaks git` which scans the full commit history,
so secrets in earlier commits are still detected even after removal from the working tree.

## Steps

1. Remove files with secrets from the working tree
   ```bash
   git rm -q config.env test/mock_tokens.json
   git commit -q -m "Remove files with secrets for history scan test"
   ```

2. Run scan on repository
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code is 1 (tokens found in history)
   ```bash
   [ "$EXIT_CODE" -eq 1 ] && echo "PASS: Exit code is 1 (tokens in history)" || echo "FAIL: Expected 1, got $EXIT_CODE"
   ```

4. Verify output indicates tokens were found
   ```bash
   echo "$OUTPUT" | grep -qiE "found|token|secret|detected" && echo "PASS: Tokens detected in history" || echo "FAIL: No token detection message"
   ```

## Expected

- Exit code: 1 (tokens found in git history)
- Output indicates tokens were detected despite removal from working tree
- Correct behavior: `git rm` does not clean git history
