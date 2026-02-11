---
tc-id: TC-004
title: Whitelist Filtering
---

## Objective

Verify that whitelisted files are excluded from scan results and non-whitelisted secrets are still detected.

## Steps

1. Create whitelist config to exclude test directory
   ```bash
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   whitelist:
     - file: "test/*"
       reason: "Test fixtures"
   EOF
   ```

2. Run scan and check whitelist behavior
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify real secret in config.env is still detected
   ```bash
   echo "$OUTPUT" | grep -qiE "token|found" && echo "PASS: Token detected in non-whitelisted file" || echo "FAIL: No token found"
   ```

4. Add a non-whitelisted secret and verify it is detected
   ```bash
   cat > real_config.env << 'EOF'
   API_KEY=ghp_RealSecretDisplay12345678901234567AB
   EOF
   git add real_config.env
   git commit -q -m "Add real config"

   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   echo "Exit code: $EXIT_CODE2"
   [ "$EXIT_CODE2" -eq 1 ] && echo "PASS: Non-whitelisted secret detected" || echo "FAIL: Expected exit 1"
   ```

## Expected

- Whitelisted files (test/*) excluded from results
- Non-whitelisted secrets (config.env, real_config.env) still detected
- Exit code 1 when non-whitelisted secrets exist
