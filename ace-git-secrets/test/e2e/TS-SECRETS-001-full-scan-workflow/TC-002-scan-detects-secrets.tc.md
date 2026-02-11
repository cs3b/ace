---
tc-id: TC-002
title: Scan Repo with Secrets (Gitleaks Detection)
---

## Objective

Verify that scanning a repository with committed secrets returns exit code 1 and reports detected tokens.

## Steps

1. Run scan (config.env with GITHUB_TOKEN is already committed via fixtures)
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 1 (secrets found)
   ```bash
   [ "$EXIT_CODE" -eq 1 ] && echo "PASS: Exit code is 1" || echo "FAIL: Expected 1, got $EXIT_CODE"
   ```

3. Verify output indicates tokens found
   ```bash
   echo "$OUTPUT" | grep -qiE "token|secret|found|alert" && echo "PASS: Token detection message" || echo "FAIL: No token message"
   ```

## Expected

- Exit code: 1
- Output contains token detection message
