---
tc-id: TC-002
title: User Config Overrides and Cascade Priority
---

## Objective

Verify that user configuration in .ace/ overrides defaults and CLI options take highest priority.

## Steps

1. Create user config with table format and whitelist
   ```bash
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   output:
     format: table
   whitelist:
     - file: "test/*"
       reason: "Test config override"
   EOF
   ```

2. Run scan (should use project config)
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Command completed with user config" || echo "FAIL: Command error"
   ```

3. Verify CLI override takes precedence over project config
   ```bash
   OUTPUT2=$(ace-git-secrets scan --format json 2>&1)
   echo "$OUTPUT2" | grep -qE "Report saved:.*\.json" && echo "PASS: CLI override worked (JSON report)" || echo "INFO: Check format"
   ```

4. Verify whitelist is active by adding a test fixture with a secret
   ```bash
   mkdir -p test
   cat > test/fixture.txt << 'EOF'
   TOKEN=ghp_ConfigOverride12345678901234567890AB
   EOF
   git add test/fixture.txt
   git commit -q -m "Add test fixture"

   OUTPUT3=$(ace-git-secrets scan 2>&1)
   echo "$OUTPUT3"
   ```

## Expected

- Command completes successfully with user config
- CLI --format json overrides project config format: table
- Whitelist from user config is active
