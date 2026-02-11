---
tc-id: TC-001
title: Load Defaults from .ace-defaults
---

## Objective

Verify that ace-git-secrets loads default configuration and operates correctly without user config.

## Steps

1. Ensure no user config exists
   ```bash
   rm -rf .ace
   ```

2. Run ace-git-secrets scan (should use defaults)
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify command completes successfully
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Command completed with defaults" || echo "FAIL: Command failed"
   ```

4. Verify output indicates normal operation
   ```bash
   echo "$OUTPUT" | grep -qiE "no tokens|clean|scan" && echo "PASS: Normal output" || echo "INFO: Check output"
   ```

## Expected

- Exit code: 0 (clean repo)
- Command works without user configuration
- Uses defaults from gem's .ace-defaults/
