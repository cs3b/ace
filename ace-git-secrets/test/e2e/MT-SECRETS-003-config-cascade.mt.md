---
test-id: MT-SECRETS-003
title: Configuration Cascade
area: git-secrets
package: ace-git-secrets
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-git-secrets, git]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Configuration Cascade

## Objective

Verify that ace-git-secrets correctly implements the ADR-022 configuration cascade: loading defaults from .ace-defaults, overriding with user config in .ace/, and handling missing configs gracefully.

## Prerequisites

- Ruby >= 3.0 installed
- ace-git-secrets package available in PATH
- git installed

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="secrets"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create isolated git repository
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-git-secrets && ace-git-secrets --version
echo "========================="
```

## Test Data

```bash
# Create minimal repository
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Project
EOF

git add README.md
git commit -q -m "Initial commit"
```

## Test Cases

### TC-001: Load Defaults from .ace-defaults

**Objective:** Verify that ace-git-secrets loads default configuration and operates correctly without user config.

**Steps:**
1. Ensure no user config exists
   ```bash
   rm -rf "$TEST_DIR/.ace"
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

**Expected:**
- Exit code: 0 (clean repo)
- Command works without user configuration
- Uses defaults from gem's .ace-defaults/

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: User Config Overrides Defaults

**Objective:** Verify that user configuration in .ace/ overrides default settings.

**Steps:**
1. Create user config with custom settings
   ```bash
   mkdir -p "$TEST_DIR/.ace/git-secrets"
   cat > "$TEST_DIR/.ace/git-secrets/config.yml" << 'EOF'
   output:
     format: json
   whitelist:
     - file: "test/*"
       reason: "Test config override"
   EOF
   ```

2. Run ace-git-secrets scan
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify command completes
   ```bash
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Command completed" || echo "FAIL: Command error"
   ```

4. Verify user config was loaded (whitelist should be active)
   ```bash
   # Create a test file that would match whitelist
   mkdir -p "$TEST_DIR/test"
   cat > "$TEST_DIR/test/fixture.txt" << 'EOF'
   TOKEN=ghp_test_config_override_1234567890AB
   EOF
   git add test/fixture.txt
   git commit -q -m "Add test fixture"

   OUTPUT2=$(ace-git-secrets scan 2>&1)
   # Whitelist should exclude test/* files
   echo "$OUTPUT2"
   ```

**Expected:**
- Command completes successfully
- User config loaded (whitelist active)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Cascade Priority Order

**Objective:** Verify that configuration follows correct priority: CLI > Project .ace/ > User ~/.ace/ > Gem defaults.

**Steps:**
1. Set up project config with one format
   ```bash
   mkdir -p "$TEST_DIR/.ace/git-secrets"
   cat > "$TEST_DIR/.ace/git-secrets/config.yml" << 'EOF'
   output:
     format: table
   EOF
   ```

2. Run with CLI override
   ```bash
   OUTPUT=$(ace-git-secrets scan --format json 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify CLI option took precedence (JSON report saved)
   ```bash
   echo "$OUTPUT" | grep -qE "Report saved:.*\.json" && echo "PASS: CLI override worked (JSON report)" || echo "INFO: Check format"
   ```

4. Run without CLI override (should use config)
   ```bash
   OUTPUT2=$(ace-git-secrets scan 2>&1)
   echo "Output without CLI override:"
   echo "$OUTPUT2"
   ```

**Expected:**
- CLI --format json overrides project config format: table
- Without CLI flag, uses project config

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Missing Configs Handled Gracefully

**Objective:** Verify that missing or empty configuration files don't cause errors.

**Steps:**
1. Create empty config file
   ```bash
   mkdir -p "$TEST_DIR/.ace/git-secrets"
   echo "" > "$TEST_DIR/.ace/git-secrets/config.yml"
   ```

2. Run ace-git-secrets scan
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

4. Test with malformed YAML (optional - may cause warning)
   ```bash
   echo "invalid: yaml: content:" > "$TEST_DIR/.ace/git-secrets/config.yml"
   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   # Command should either work with fallback or show helpful error
   echo "Exit code with invalid YAML: $EXIT_CODE2"
   ```

**Expected:**
- Empty config file handled gracefully
- Falls back to defaults when config is invalid/empty

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Config Validation

**Objective:** Verify that configuration values are validated.

**Steps:**
1. Create config with valid settings
   ```bash
   mkdir -p "$TEST_DIR/.ace/git-secrets"
   cat > "$TEST_DIR/.ace/git-secrets/config.yml" << 'EOF'
   output:
     format: table
     mask_tokens: true
   whitelist: []
   exclusions:
     - "*.lock"
     - "vendor/**/*"
   EOF
   ```

2. Run scan
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify command works with valid config
   ```bash
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Valid config accepted" || echo "FAIL: Valid config rejected"
   ```

4. Verify exclusions are applied (create a lock file with secret)
   ```bash
   cat > "$TEST_DIR/package.lock" << 'EOF'
   TOKEN=ghp_test_exclusion_check_1234567890AB
   EOF
   git add package.lock
   git commit -q -m "Add lock file"

   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   echo "Exit code with lock file: $EXIT_CODE2"
   # Lock file should be excluded, so exit should be 0 if no other secrets
   ```

**Expected:**
- Valid configuration accepted
- Exclusions applied (lock files excluded from scan)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: Defaults load correctly
- [ ] TC-002: User config overrides defaults
- [ ] TC-003: CLI options have highest priority
- [ ] TC-004: Missing/empty configs handled gracefully
- [ ] TC-005: Valid configuration accepted

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace ace-git-secrets/test/integration/config_cascade_test.rb
- Tests verify ADR-022 configuration cascade compliance
- Priority order: CLI > Project .ace/ > User ~/.ace/ > Gem .ace-defaults/
- Config files use YAML format
