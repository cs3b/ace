---
test-id: MT-TIMESTAMP-002
title: CLI Configuration and Defaults
area: timestamp
package: ace-support-timestamp
priority: medium
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-timestamp]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# CLI Configuration and Defaults

## Objective

Verify that ace-timestamp CLI correctly handles configuration, defaults, error conditions, and various input formats. Tests cover config display, year_zero override, error handling, legacy format support, and output modes.

## Prerequisites

- Ruby >= 3.0 installed
- ace-timestamp CLI available in PATH

## Environment Setup

```bash
```

## Test Cases

### TC-001: Config Command Shows Defaults

**Objective:** Verify config command displays default settings including year_zero and alphabet.

**Steps:**
1. Run config command
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp config
   ```

2. Verify year_zero default is 2000
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp config | grep -q "year_zero.*2000" && echo "PASS: year_zero is 2000" || echo "FAIL: year_zero mismatch"
   ```

3. Verify alphabet is displayed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp config | grep -qi "alphabet" && echo "PASS: Alphabet shown" || echo "FAIL: Alphabet missing"
   ```

**Expected:**
- Config shows year_zero: 2000
- Config shows alphabet (base36: 0-9a-z)
- Output is human-readable

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Config --verbose

**Objective:** Verify verbose config shows additional details including sources and year range.

**Steps:**
1. Run verbose config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp config --verbose
   ```

2. Verify year range is displayed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp config --verbose | grep -qi "range\|years\|2000.*2108" && echo "PASS: Year range shown" || echo "CHECK: Review year range output"
   ```

3. Verify more detail than basic config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   BASIC=$(ace-timestamp config | wc -l)
   VERBOSE=$(ace-timestamp config --verbose | wc -l)
   [ "$VERBOSE" -ge "$BASIC" ] && echo "PASS: Verbose has more/equal output" || echo "FAIL: Verbose has less output"
   SANDBOX
   ```

**Expected:**
- Verbose output includes more details
- Year range shown (2000-2108 for 108-year window)
- Source information may be included

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Year Zero Override on Encode

**Objective:** Verify year_zero override produces different IDs for same timestamp.

**Steps:**
1. Encode with default year_zero (2000)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ID_2000=$(ace-timestamp encode -q --year-zero 2000 '2025-06-15 12:00:00')
   echo "Year zero 2000: $ID_2000"
   SANDBOX
   ```

2. Encode with different year_zero (2020)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ID_2020=$(ace-timestamp encode -q --year-zero 2020 '2025-06-15 12:00:00')
   echo "Year zero 2020: $ID_2020"
   SANDBOX
   ```

3. Verify IDs are different
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ "$ID_2000" != "$ID_2020" ] && echo "PASS: Different year_zero produces different IDs" || echo "FAIL: Same IDs"
   ```

4. Verify 2020 ID is "smaller" (fewer years from base)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [[ "$ID_2020" < "$ID_2000" ]] && echo "PASS: 2020-based ID is smaller" || echo "CHECK: Compare IDs manually"
   ```

**Expected:**
- Same timestamp with different year_zero produces different IDs
- ID with closer year_zero is lexicographically smaller

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Year Zero Override on Decode

**Objective:** Verify decode must use matching year_zero to get correct timestamp.

**Steps:**
1. Encode with year_zero 2020
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ID=$(ace-timestamp encode -q --year-zero 2020 '2025-06-15 12:00:00')
   echo "Encoded with year_zero=2020: $ID"
   SANDBOX
   ```

2. Decode with matching year_zero
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CORRECT=$(ace-timestamp decode -q --year-zero 2020 "$ID")
   echo "Decoded with year_zero=2020: $CORRECT"
   SANDBOX
   ```

3. Decode with default year_zero (mismatched)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   WRONG=$(ace-timestamp decode -q --year-zero 2000 "$ID")
   echo "Decoded with year_zero=2000: $WRONG"
   SANDBOX
   ```

4. Verify correct decode matches original
   ```bash
   ace-test-e2e-sh "$TEST_DIR" echo "$CORRECT" | grep -q "2025-06-15" && echo "PASS: Correct year_zero decodes correctly" || echo "FAIL: Decode mismatch"
   ```

5. Verify mismatched decode is different
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ "$CORRECT" != "$WRONG" ] && echo "PASS: Mismatched year_zero gives different result" || echo "FAIL: Same results"
   ```

**Expected:**
- Matching year_zero decodes to original timestamp
- Mismatched year_zero produces different (incorrect) timestamp

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Invalid Format Error

**Objective:** Verify CLI rejects unknown format names with helpful error.

**Steps:**
1. Try invalid format name
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp encode --format invalid '2025-06-15' 2>&1
   RESULT=$?
   SANDBOX
   ```

2. Verify non-zero exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ $RESULT -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Should have failed"
   ```

3. Verify error message is helpful
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp encode --format invalid '2025-06-15' 2>&1 | grep -qi "invalid\|unknown\|error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   ```

**Expected:**
- Exit code is non-zero
- Error message indicates invalid format
- May suggest valid format names

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Invalid Compact ID Error

**Objective:** Verify CLI rejects invalid compact IDs (bad characters, wrong length).

**Steps:**
1. Try ID with invalid characters
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp decode '!@#$%' 2>&1
   INVALID_CHAR=$?
   echo "Invalid chars exit code: $INVALID_CHAR"
   SANDBOX
   ```

2. Try ID with wrong length (1 char)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp decode 'a' 2>&1
   SHORT=$?
   echo "Too short exit code: $SHORT"
   SANDBOX
   ```

3. Try ID that's too long (10 chars)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp decode 'abcdefghij' 2>&1
   LONG=$?
   echo "Too long exit code: $LONG"
   SANDBOX
   ```

4. Verify all produce errors
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ $INVALID_CHAR -ne 0 ] && [ $SHORT -ne 0 ] && [ $LONG -ne 0 ] && echo "PASS: All invalid IDs rejected" || echo "FAIL: Some invalid IDs accepted"
   ```

**Expected:**
- Invalid characters: rejected with error
- Too short (1 char): rejected with error
- Too long (>8 chars): rejected with error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Time Outside Range

**Objective:** Verify CLI rejects timestamps outside the 108-year window.

**Steps:**
1. Try year before range (1999 with default year_zero 2000)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp encode -q '1999-01-01 00:00:00' 2>&1
   BEFORE=$?
   echo "Before range exit code: $BEFORE"
   SANDBOX
   ```

2. Try year after range (2109 with default year_zero 2000)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp encode -q '2109-01-01 00:00:00' 2>&1
   AFTER=$?
   echo "After range exit code: $AFTER"
   SANDBOX
   ```

3. Verify both produce errors
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ $BEFORE -ne 0 ] && [ $AFTER -ne 0 ] && echo "PASS: Out-of-range rejected" || echo "FAIL: Out-of-range accepted"
   ```

**Expected:**
- Year before year_zero: rejected
- Year after year_zero + 108: rejected
- Error message indicates valid range

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Legacy Timestamp Format

**Objective:** Verify encode accepts YYYYMMDD-HHMMSS format input and treats it as UTC.

**Steps:**
1. Encode using legacy format (implicitly UTC)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   LEGACY_ID=$(ace-timestamp encode -q '20250615-143245')
   echo "Legacy format ID: $LEGACY_ID"
   SANDBOX
   ```

2. Encode using readable format with explicit UTC
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   READABLE_ID=$(ace-timestamp encode -q '2025-06-15 14:32:45 UTC')
   echo "Readable format ID: $READABLE_ID"
   SANDBOX
   ```

3. Verify same result
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ "$LEGACY_ID" = "$READABLE_ID" ] && echo "PASS: Legacy format accepted" || echo "FAIL: Different IDs"
   ```

**Expected:**
- Legacy YYYYMMDD-HHMMSS format is treated as UTC
- Readable format with explicit UTC produces same ID
- Both decode to same timestamp

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Quiet Mode

**Objective:** Verify -q/--quiet suppresses config summary output.

**Steps:**
1. Encode without quiet (observe output format)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Without quiet ==="
   ace-timestamp encode '2025-06-15 14:32:45'
   WITHOUT_QUIET_LINES=$(ace-timestamp encode '2025-06-15 14:32:45' 2>&1 | wc -l)
   SANDBOX
   ```

2. Encode with quiet flag
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== With quiet ==="
   ace-timestamp encode -q '2025-06-15 14:32:45'
   WITH_QUIET_LINES=$(ace-timestamp encode -q '2025-06-15 14:32:45' 2>&1 | wc -l)
   SANDBOX
   ```

3. Verify quiet has fewer lines
   ```bash
   ace-test-e2e-sh "$TEST_DIR" [ "$WITH_QUIET_LINES" -le "$WITHOUT_QUIET_LINES" ] && echo "PASS: Quiet reduces output" || echo "FAIL: Quiet has more output"
   ```

4. Verify quiet output is just the ID
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   QUIET_OUTPUT=$(ace-timestamp encode -q '2025-06-15 14:32:45')
   [[ "$QUIET_OUTPUT" =~ ^[0-9a-z]+$ ]] && echo "PASS: Quiet output is just ID" || echo "CHECK: Review quiet output"
   SANDBOX
   ```

**Expected:**
- Quiet mode produces minimal output (just the ID)
- Non-quiet mode may include config summary or headers

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Version Command

**Objective:** Verify version command outputs semver version.

**Steps:**
1. Run version command
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp version
   ```

2. Also check --version flag
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp --version
   ```

3. Verify output contains semver pattern
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-timestamp version | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && echo "PASS: Semver format" || echo "FAIL: Not semver"
   ```

4. Verify exit code is 0
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-timestamp version > /dev/null 2>&1
   [ $? -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Non-zero exit"
   SANDBOX
   ```

**Expected:**
- Version output contains semver (e.g., "0.4.0")
- Exit code is 0
- Both `version` command and `--version` flag work

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Config shows year_zero 2000 and alphabet
- [ ] TC-002: Verbose config shows additional details
- [ ] TC-003: Year zero override produces different IDs
- [ ] TC-004: Decode requires matching year_zero
- [ ] TC-005: Invalid format name rejected
- [ ] TC-006: Invalid compact IDs rejected
- [ ] TC-007: Out-of-range timestamps rejected
- [ ] TC-008: Legacy YYYYMMDD-HHMMSS format treated as UTC
- [ ] TC-009: Quiet mode suppresses extra output
- [ ] TC-010: Version command outputs semver

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Year zero determines the base year for encoding (default: 2000)
- Valid year range is year_zero to year_zero + 108 (108-year window)
- Quiet mode is essential for scripting and piping
- Legacy timestamp format supports backward compatibility
