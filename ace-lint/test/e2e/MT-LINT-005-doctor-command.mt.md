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
last-verified: null
verified-by: null
---

# Doctor Command Functionality

## Objective

Verify that the `ace-lint doctor` command correctly lists available validators, shows configuration status, validates YAML syntax, detects invalid YAML with appropriate exit codes, and respects quiet and verbose modes.

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt005"
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

# Another valid config with groups
mkdir -p "$TEST_DIR/groups-config/.ace/lint"
cat > "$TEST_DIR/groups-config/.ace/lint/ruby.yml" << 'EOF'
groups:
  default:
    patterns:
      - "**/*.rb"
    validators:
      - standardrb
EOF

# Invalid YAML configuration (bad indentation)
mkdir -p "$TEST_DIR/invalid-config/.ace/lint"
cat > "$TEST_DIR/invalid-config/.ace/lint/ruby.yml" << 'EOF'
groups:
  default:
    patterns:
      - "**/*.rb"
    validators: [notarealvalidator
EOF

# Configuration with syntax error (missing closing bracket)
mkdir -p "$TEST_DIR/syntax-error/.ace/lint"
cat > "$TEST_DIR/syntax-error/.ace/lint/config.yml" << 'EOF'
kramdown:
  auto_ids: true
  entity_output: numeric
    bad_indent: yes
EOF
```

## Test Cases

### TC-001: Doctor Lists Available Validators

**Objective:** Verify that doctor command shows available validators.

**Steps:**
1. Run doctor command without any config
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify validators are listed
   ```bash
   echo "$OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators mentioned" || echo "FAIL: No validators found in output"
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
   cd "$TEST_DIR/valid-config"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify config information is shown
   ```bash
   echo "$OUTPUT" | grep -qiE "config|configuration|\.ace" && echo "PASS: Config info present" || echo "FAIL: No config info"
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
   cd "$TEST_DIR/groups-config"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify valid status is shown
   ```bash
   echo "$OUTPUT" | grep -qiE "valid|ok|pass" && echo "PASS: Valid status shown" || echo "INFO: Valid status not explicitly shown"
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
   cd "$TEST_DIR/invalid-config"
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify exit code is 2 (error)
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2 for YAML error" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   ```

3. Check for error indication in output
   ```bash
   echo "$OUTPUT" | grep -qiE "error|invalid|syntax|parse" && echo "PASS: Error indication in output" || echo "INFO: Error not explicitly shown"
   ```

**Expected:**
- Exit code: 2 (indicates error)
- Output may indicate YAML syntax error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Doctor Quiet Mode

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

### TC-006: Doctor Verbose Mode

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

### TC-007: Error - Doctor Exit Code 0 When Healthy

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

### TC-008: Error - Doctor Exit Code 2 on Syntax Error

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

- [ ] TC-001: Doctor lists available validators
- [ ] TC-002: Doctor shows configuration status
- [ ] TC-003: Doctor validates YAML syntax
- [ ] TC-004: Doctor detects invalid YAML (exit code 2)
- [ ] TC-005: Doctor quiet mode suppresses output
- [ ] TC-006: Doctor verbose mode shows additional details
- [ ] TC-007: Exit code 0 or 1 when healthy
- [ ] TC-008: Exit code 2 on syntax error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-lint/test/integration/doctor_integration_test.rb
- Exit codes: 0 = healthy, 1 = warnings (e.g., missing validators), 2 = errors (invalid config)
- Quiet and verbose modes affect output verbosity but not exit codes
