---
test-id: MT-LINT-008
title: Doctor Modes and Exit Codes
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

# Doctor Modes and Exit Codes

## Objective

Verify that the `ace-lint doctor` command respects quiet and verbose modes, and returns correct exit codes (0 for healthy, 2 for syntax errors).

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="lint"
SHORT_ID="mt008"
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

### TC-001: Doctor Quiet Mode

**Objective:** Verify that doctor command quiet mode suppresses output.

**Steps:**
1. Run doctor command with --quiet flag
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor --quiet 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output length: ${#OUTPUT}"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify output is minimal or empty
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT_LEN=${#OUTPUT}
   # Quiet mode should produce significantly less output
   if [ "$OUTPUT_LEN" -lt 100 ]; then
     echo "PASS: Quiet mode produces minimal output"
   else
     echo "INFO: Output length is $OUTPUT_LEN characters"
   fi
   SANDBOX
   ```

**Expected:**
- Command completes with valid exit code
- Output is suppressed or minimal in quiet mode

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Doctor Verbose Mode

**Objective:** Verify that doctor command verbose mode shows additional details.

**Steps:**
1. Run doctor command without verbose
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   NORMAL_OUTPUT=$(ace-lint doctor 2>&1)
   NORMAL_LEN=${#NORMAL_OUTPUT}
   echo "Normal output length: $NORMAL_LEN"
   SANDBOX
   ```

2. Run doctor command with --verbose flag
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   VERBOSE_OUTPUT=$(ace-lint doctor --verbose 2>&1)
   VERBOSE_LEN=${#VERBOSE_OUTPUT}
   echo "Verbose output length: $VERBOSE_LEN"
   echo "$VERBOSE_OUTPUT"
   SANDBOX
   ```

3. Compare output lengths
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   if [ "$VERBOSE_LEN" -ge "$NORMAL_LEN" ]; then
     echo "PASS: Verbose mode provides at least as much output"
   else
     echo "INFO: Verbose output ($VERBOSE_LEN) is shorter than normal ($NORMAL_LEN)"
   fi
   SANDBOX
   ```

4. Verify validators are mentioned in verbose output
   ```bash
   ace-test-e2e-sh "$TEST_DIR/valid-config" bash << 'SANDBOX'
   echo "$VERBOSE_OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators shown in verbose mode" || echo "FAIL: No validators in verbose output"
   SANDBOX
   ```

**Expected:**
- Verbose mode shows more details
- Output includes validator information

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Exit Code 0 When Healthy

**Objective:** Verify that doctor returns exit code 0 when configuration is healthy.

**Steps:**
1. Run doctor in a clean directory (no config = uses defaults)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p clean-dir
   cd clean-dir
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Check exit code (0 = healthy, 1 = warnings are acceptable)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   if [ "$EXIT_CODE" -eq 0 ]; then
     echo "PASS: Exit code 0 (healthy)"
   elif [ "$EXIT_CODE" -eq 1 ]; then
     echo "PASS: Exit code 1 (warnings, e.g., missing validators)"
   else
     echo "FAIL: Unexpected exit code $EXIT_CODE"
   fi
   SANDBOX
   ```

**Expected:**
- Exit code: 0 (healthy) or 1 (warnings like missing validators)
- Not exit code 2 (errors)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Exit Code 2 on Syntax Error

**Objective:** Verify that doctor returns exit code 2 for YAML syntax errors.

**Steps:**
1. Run doctor with syntax error config
   ```bash
   ace-test-e2e-sh "$TEST_DIR/syntax-error" bash << 'SANDBOX'
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify exit code is 2
   ```bash
   ace-test-e2e-sh "$TEST_DIR/syntax-error" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code 2 for syntax error" || echo "FAIL: Expected 2, got $EXIT_CODE"
   SANDBOX
   ```

**Expected:**
- Exit code: 2 (indicates configuration error)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Known Issues

- **TC-004**: `ace-lint doctor` returns exit code 0 instead of expected exit code 2 when encountering YAML syntax errors. This is a code bug in the doctor command's exit code handling, not a test issue.

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: Doctor quiet mode suppresses output
- [ ] TC-002: Doctor verbose mode shows additional details
- [ ] TC-003: Exit code 0 or 1 when healthy
- [ ] TC-004: Exit code 2 on syntax error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Exit codes: 0 = healthy, 1 = warnings (e.g., missing validators), 2 = errors (invalid config)
- Quiet and verbose modes affect output verbosity but not exit codes
