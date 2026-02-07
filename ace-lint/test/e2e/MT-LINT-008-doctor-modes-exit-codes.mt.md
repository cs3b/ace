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
last-verified: null
verified-by: null
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

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt008"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
echo "========================="
```

## Test Data

```bash
# Valid YAML configuration
mkdir -p "$TEST_DIR/valid-config/.ace/lint"
cat > "$TEST_DIR/valid-config/.ace/lint/config.yml" << 'EOF'
kramdown:
  auto_ids: true
  entity_output: numeric
EOF

# Configuration with syntax error (bad indentation)
mkdir -p "$TEST_DIR/syntax-error/.ace/lint"
git -C "$TEST_DIR/syntax-error" init --quiet .
cat > "$TEST_DIR/syntax-error/.ace/lint/.standard.yml" << 'EOF'
kramdown:
  auto_ids: true
  entity_output: numeric
    bad_indent: yes
EOF
```

## Test Cases

### TC-001: Doctor Quiet Mode

**Objective:** Verify that doctor command quiet mode suppresses output.

**Steps:**
1. Run doctor command with --quiet flag
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-lint doctor --quiet 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output length: ${#OUTPUT}"
   echo "Output: $OUTPUT"
   ```

2. Verify output is minimal or empty
   ```bash
   OUTPUT_LEN=${#OUTPUT}
   # Quiet mode should produce significantly less output
   if [ "$OUTPUT_LEN" -lt 100 ]; then
     echo "PASS: Quiet mode produces minimal output"
   else
     echo "INFO: Output length is $OUTPUT_LEN characters"
   fi
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
   cd "$TEST_DIR/valid-config"
   NORMAL_OUTPUT=$(ace-lint doctor 2>&1)
   NORMAL_LEN=${#NORMAL_OUTPUT}
   echo "Normal output length: $NORMAL_LEN"
   ```

2. Run doctor command with --verbose flag
   ```bash
   VERBOSE_OUTPUT=$(ace-lint doctor --verbose 2>&1)
   VERBOSE_LEN=${#VERBOSE_OUTPUT}
   echo "Verbose output length: $VERBOSE_LEN"
   echo "$VERBOSE_OUTPUT"
   ```

3. Compare output lengths
   ```bash
   if [ "$VERBOSE_LEN" -ge "$NORMAL_LEN" ]; then
     echo "PASS: Verbose mode provides at least as much output"
   else
     echo "INFO: Verbose output ($VERBOSE_LEN) is shorter than normal ($NORMAL_LEN)"
   fi
   ```

4. Verify validators are mentioned in verbose output
   ```bash
   echo "$VERBOSE_OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators shown in verbose mode" || echo "FAIL: No validators in verbose output"
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
   mkdir -p "$TEST_DIR/clean-dir"
   cd "$TEST_DIR/clean-dir"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Check exit code (0 = healthy, 1 = warnings are acceptable)
   ```bash
   if [ "$EXIT_CODE" -eq 0 ]; then
     echo "PASS: Exit code 0 (healthy)"
   elif [ "$EXIT_CODE" -eq 1 ]; then
     echo "PASS: Exit code 1 (warnings, e.g., missing validators)"
   else
     echo "FAIL: Unexpected exit code $EXIT_CODE"
   fi
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
   cd "$TEST_DIR/syntax-error"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify exit code is 2
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code 2 for syntax error" || echo "FAIL: Expected 2, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 2 (indicates configuration error)

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

- [ ] TC-001: Doctor quiet mode suppresses output
- [ ] TC-002: Doctor verbose mode shows additional details
- [ ] TC-003: Exit code 0 or 1 when healthy
- [ ] TC-004: Exit code 2 on syntax error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Exit codes: 0 = healthy, 1 = warnings (e.g., missing validators), 2 = errors (invalid config)
- Quiet and verbose modes affect output verbosity but not exit codes
