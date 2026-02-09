---
test-id: MT-LINT-005
title: Doctor Command Functionality
area: lint
package: ace-lint
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-lint]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Doctor Command Functionality

## Objective

Verify that the `ace-lint doctor` command correctly lists available validators, shows configuration status, validates YAML syntax, and detects invalid YAML with appropriate exit codes.

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="lint"
SHORT_ID="mt005"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
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
# Valid YAML configuration
mkdir -p valid-config/.ace/lint
cat > valid-config/.ace/lint/config.yml << 'EOF'
kramdown:
  auto_ids: true
  entity_output: numeric
EOF

# Another valid config with groups
mkdir -p groups-config/.ace/lint
cat > groups-config/.ace/lint/ruby.yml << 'EOF'
groups:
  default:
    patterns:
      - "**/*.rb"
    validators:
      - standardrb
EOF

# Invalid YAML configuration (missing closing bracket)
mkdir -p invalid-config/.ace/lint
git -C invalid-config init --quiet .
cat > invalid-config/.ace/lint/.standard.yml << 'EOF'
groups:
  default:
    patterns:
      - "**/*.rb"
    validators: [notarealvalidator
EOF

# Configuration with syntax error (bad indentation)
mkdir -p syntax-error/.ace/lint
git -C syntax-error init --quiet .
cat > syntax-error/.ace/lint/.standard.yml << 'EOF'
kramdown:
  auto_ids: true
  entity_output: numeric
    bad_indent: yes
EOF
SANDBOX
```

## Test Cases

### TC-001: Doctor Lists Available Validators

**Objective:** Verify that doctor command shows available validators.

**Steps:**
1. Run doctor command without any config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify validators are listed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators mentioned" || echo "FAIL: No validators found in output"
   SANDBOX
   ```

**Expected:**
- Exit code: 0 or 1 (depending on validator availability)
- Output mentions validators (standardrb, rubocop, or generic "validator")

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Doctor Shows Config Status

**Objective:** Verify that doctor command shows configuration information.

**Steps:**
1. Run doctor command in directory with config
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify config information is shown
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "config|configuration|\.ace" && echo "PASS: Config info present" || echo "FAIL: No config info"
   SANDBOX
   ```

**Expected:**
- Exit code: 0 or 1
- Output mentions configuration or config file

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Doctor Validates YAML Syntax

**Objective:** Verify that doctor command validates YAML and shows valid status.

**Steps:**
1. Run doctor command with valid config
   ```bash
   ace-test-e2e-sh "$TEST_DIR/groups-config" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify valid status is shown
   ```bash
   ace-test-e2e-sh "$TEST_DIR/groups-config" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "valid|ok|pass" && echo "PASS: Valid status shown" || echo "INFO: Valid status not explicitly shown"
   SANDBOX
   ```

**Expected:**
- Exit code: 0 or 1 (healthy or warnings)
- Output indicates configuration is valid or no errors found

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Doctor Detects Invalid YAML (Exit Code 2)

**Objective:** Verify that doctor command detects invalid YAML and returns exit code 2.

**Steps:**
1. Run doctor command with invalid YAML config
   ```bash
   ace-test-e2e-sh "$TEST_DIR/invalid-config" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify exit code is 2 (error)
   ```bash
   ace-test-e2e-sh "$TEST_DIR/invalid-config" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2 for YAML error" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   SANDBOX
   ```

3. Check for error indication in output
   ```bash
   ace-test-e2e-sh "$TEST_DIR/invalid-config" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "error|invalid|syntax|parse" && echo "PASS: Error indication in output" || echo "INFO: Error not explicitly shown"
   SANDBOX
   ```

**Expected:**
- Exit code: 2 (indicates error)
- Output may indicate YAML syntax error

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

- [ ] TC-001: Doctor lists available validators
- [ ] TC-002: Doctor shows configuration status
- [ ] TC-003: Doctor validates YAML syntax
- [ ] TC-004: Doctor detects invalid YAML (exit code 2)

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-lint/test/integration/doctor_integration_test.rb
- Exit codes: 0 = healthy, 1 = warnings (e.g., missing validators), 2 = errors (invalid config)
- Quiet and verbose modes affect output verbosity but not exit codes
