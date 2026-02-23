---
tc-id: TC-001
title: Healthy Environment
---

## Objective

Verify that `ace-lint --doctor` in a healthy environment (valid config, validators available) exits without error, mentions validators, and shows config information.

## Steps

1. Run doctor in the valid-config directory
   ```bash
   cd valid-config
   OUTPUT=$(ace-lint --doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify exit code is not 2 (error)
   ```bash
   [ "$EXIT_CODE" -ne 2 ] && echo "PASS: Exit code is not 2 (got $EXIT_CODE)" || echo "FAIL: Exit code is 2 (error state)"
   ```

3. Verify validators are mentioned
   ```bash
   echo "$OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators mentioned" || echo "FAIL: No validators in output"
   ```

4. Verify config information is shown
   ```bash
   echo "$OUTPUT" | grep -qiE "config|configuration|\.ace" && echo "PASS: Config info present" || echo "FAIL: No config info"
   ```

## Expected

- Exit code: 0 or 1 (not 2, which indicates error)
- Output mentions validators (standardrb, rubocop, or generic "validator")
- Output shows configuration information
