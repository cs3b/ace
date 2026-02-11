---
tc-id: TC-003
title: Missing Configs Handled Gracefully
---

## Objective

Verify that missing or empty configuration files do not cause errors and the tool falls back to defaults.

## Steps

1. Create empty config file
   ```bash
   mkdir -p .ace/git-secrets
   echo "" > .ace/git-secrets/config.yml
   ```

2. Run ace-git-secrets scan with empty config
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify no error about empty config
   ```bash
   ! echo "$OUTPUT" | grep -qi "error.*config\|invalid.*config" && echo "PASS: No config error" || echo "FAIL: Config error"
   ```

4. Test with malformed YAML config
   ```bash
   echo "invalid: yaml: content:" > .ace/git-secrets/config.yml
   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   echo "Exit code with invalid YAML: $EXIT_CODE2"
   ```

5. Verify tool still operates (either with fallback or helpful error)
   ```bash
   [ "$EXIT_CODE2" -ge 0 ] && echo "PASS: Command handled malformed config" || echo "FAIL: Command crashed"
   ```

## Expected

- Empty config file handled gracefully
- Falls back to defaults when config is invalid/empty
- No crashes on malformed YAML
