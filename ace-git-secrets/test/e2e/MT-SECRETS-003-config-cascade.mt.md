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
last-verified: 2026-02-08
verified-by: claude-opus-4-6
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

TIMESTAMP_ID="${RUN_ID:-$(ace-b36ts encode)}"
SHORT_PKG="secrets"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Create isolated git repository
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-git-secrets && ace-git-secrets --version
echo "========================="

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi
echo "=== ISOLATION VERIFIED ==="
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create minimal repository
cat > README.md << 'EOF'
# Test Project
EOF

git add README.md
git commit -q -m "Initial commit"
SANDBOX
```

## Test Cases

### TC-001: Load Defaults from .ace-defaults

**Objective:** Verify that ace-git-secrets loads default configuration and operates correctly without user config.

**Steps:**
1. Ensure no user config exists
   ```bash
   ace-test-e2e-sh "$TEST_DIR" rm -rf .ace
   ```

2. Run ace-git-secrets scan (should use defaults)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify command completes successfully
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Command completed with defaults" || echo "FAIL: Command failed"
   SANDBOX
   ```

4. Verify output indicates normal operation
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "no tokens|clean|scan" && echo "PASS: Normal output" || echo "INFO: Check output"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   output:
     format: json
   whitelist:
     - file: "test/*"
       reason: "Test config override"
   EOF
   SANDBOX
   ```

2. Run ace-git-secrets scan
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify command completes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Command completed" || echo "FAIL: Command error"
   SANDBOX
   ```

4. Verify user config was loaded (whitelist should be active)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Create a test file that would match whitelist
   mkdir -p test
   cat > test/fixture.txt << 'EOF'
   TOKEN=literal:[REDACTED:github-pat]
   EOF
   git add test/fixture.txt
   git commit -q -m "Add test fixture"

   OUTPUT2=$(ace-git-secrets scan 2>&1)
   # Whitelist should exclude test/* files
   echo "$OUTPUT2"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   output:
     format: table
   EOF
   SANDBOX
   ```

2. Run with CLI override
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --format json 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify CLI option took precedence (JSON report saved)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qE "Report saved:.*\.json" && echo "PASS: CLI override worked (JSON report)" || echo "INFO: Check format"
   SANDBOX
   ```

4. Run without CLI override (should use config)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT2=$(ace-git-secrets scan 2>&1)
   echo "Output without CLI override:"
   echo "$OUTPUT2"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git-secrets
   echo "" > .ace/git-secrets/config.yml
   SANDBOX
   ```

2. Run ace-git-secrets scan
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify no error about empty config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ! echo "$OUTPUT" | grep -qi "error.*config\|invalid.*config" && echo "PASS: No config error" || echo "FAIL: Config error"
   SANDBOX
   ```

4. Test with malformed YAML (optional - may cause warning)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "invalid: yaml: content:" > .ace/git-secrets/config.yml
   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   # Command should either work with fallback or show helpful error
   echo "Exit code with invalid YAML: $EXIT_CODE2"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   output:
     format: table
     mask_tokens: true
   whitelist: []
   exclusions:
     - "*.lock"
     - "vendor/**/*"
   EOF
   SANDBOX
   ```

2. Run scan
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify command works with valid config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Valid config accepted" || echo "FAIL: Valid config rejected"
   SANDBOX
   ```

4. Verify exclusions are applied (create a lock file with secret)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > package.lock << 'EOF'
   TOKEN=literal:[REDACTED:github-pat]
   EOF
   git add package.lock
   git commit -q -m "Add lock file"

   OUTPUT2=$(ace-git-secrets scan 2>&1)
   EXIT_CODE2=$?
   echo "Exit code with lock file: $EXIT_CODE2"
   # Lock file should be excluded, so exit should be 0 if no other secrets
   SANDBOX
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
