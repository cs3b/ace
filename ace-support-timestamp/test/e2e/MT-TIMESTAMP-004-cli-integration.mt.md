---
test-id: MT-TIMESTAMP-004
title: CLI Integration Tests
area: timestamp
package: ace-support-timestamp
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-timestamp]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# CLI Integration Tests

## Objective

Verify that ace-timestamp CLI correctly handles encode/decode roundtrips across all format precisions, provides proper error handling for invalid inputs, and displays help and version information correctly. These tests execute the actual binary and validate the full pipeline from command line to output.

## Prerequisites

- Ruby >= 3.0 installed
- ace-timestamp CLI available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode -q)"
SHORT_PKG="support-timestamp"
SHORT_ID="mt004"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ace-timestamp && ace-timestamp version
echo "========================="
```

## Test Data

```bash
# Test timestamps and invalid inputs
TEST_TIMESTAMP="2025-06-15 12:30:45 UTC"
INVALID_ID="invalid!!!"
INVALID_FORMAT="nonexistent"
```

## Test Cases

### TC-001: Error - Invalid ID Decode

**Objective:** Verify that ace-timestamp decode handles invalid IDs with a clear error message and non-zero exit code.

**Steps:**
1. Attempt to decode an invalid ID
   ```bash
   OUTPUT=$(ace-timestamp decode "invalid!!!" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code and error message
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   ```

**Expected:**
- Exit code: non-zero
- Output contains: "error" (case-insensitive)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Error - Invalid Format Encode

**Objective:** Verify that ace-timestamp encode handles invalid format options with a clear error message and non-zero exit code.

**Steps:**
1. Attempt to encode with an invalid format
   ```bash
   OUTPUT=$(ace-timestamp encode --format nonexistent '2025-06-15' 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code and error message
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   ```

**Expected:**
- Exit code: non-zero
- Output contains: "error" (case-insensitive)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Encode-Decode Roundtrip - 2sec Format (Default)

**Objective:** Verify encode/decode roundtrip works correctly for the default 2sec format.

**Steps:**
1. Encode a specific timestamp
   ```bash
   ENCODED=$(ace-timestamp encode -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 6 characters
   ```bash
   [ ${#ENCODED} -eq 6 ] && echo "PASS: Length is 6" || echo "FAIL: Length is ${#ENCODED}"
   [[ "$ENCODED" =~ ^[0-9a-z]+$ ]] && echo "PASS: Valid base36" || echo "FAIL: Invalid characters"
   ```

3. Decode the ID
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   ```

4. Verify decoded date and approximate time
   ```bash
   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   echo "$DECODED" | grep -q "12:3" && echo "PASS: Approximate time matches" || echo "FAIL: Time mismatch"
   ```

**Expected:**
- Encoded ID is exactly 6 characters (base36)
- Decoded output contains original date (2025-06-15)
- Decoded output contains approximate time (12:3X)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Encode-Decode Roundtrip - Month Format (2 chars)

**Objective:** Verify encode/decode roundtrip works correctly for month format.

**Steps:**
1. Encode to month format
   ```bash
   ENCODED=$(ace-timestamp encode --format month -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 2 characters
   ```bash
   [ ${#ENCODED} -eq 2 ] && echo "PASS: Length is 2" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06" && echo "PASS: Month matches" || echo "FAIL: Month mismatch"
   ```

**Expected:**
- Encoded ID is exactly 2 characters
- Decoded output contains year and month (2025-06)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Encode-Decode Roundtrip - Day Format (3 chars)

**Objective:** Verify encode/decode roundtrip works correctly for day format.

**Steps:**
1. Encode to day format
   ```bash
   ENCODED=$(ace-timestamp encode --format day -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 3 characters
   ```bash
   [ ${#ENCODED} -eq 3 ] && echo "PASS: Length is 3" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   ```

**Expected:**
- Encoded ID is exactly 3 characters
- Decoded output contains full date (2025-06-15)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Encode-Decode Roundtrip - Week Format (3 chars)

**Objective:** Verify encode/decode roundtrip works correctly for week format.

**Steps:**
1. Encode to week format
   ```bash
   ENCODED=$(ace-timestamp encode --format week -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 3 characters
   ```bash
   [ ${#ENCODED} -eq 3 ] && echo "PASS: Length is 3" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06" && echo "PASS: Month matches" || echo "FAIL: Month mismatch"
   ```

**Expected:**
- Encoded ID is exactly 3 characters
- Decoded output contains year and month (2025-06)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Encode-Decode Roundtrip - 40min Format (4 chars)

**Objective:** Verify encode/decode roundtrip works correctly for 40min format.

**Steps:**
1. Encode to 40min format
   ```bash
   ENCODED=$(ace-timestamp encode --format 40min -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 4 characters
   ```bash
   [ ${#ENCODED} -eq 4 ] && echo "PASS: Length is 4" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   ```

**Expected:**
- Encoded ID is exactly 4 characters
- Decoded output contains full date (2025-06-15)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Encode-Decode Roundtrip - 50ms Format (7 chars)

**Objective:** Verify encode/decode roundtrip works correctly for 50ms format.

**Steps:**
1. Encode to 50ms format
   ```bash
   ENCODED=$(ace-timestamp encode --format 50ms -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 7 characters
   ```bash
   [ ${#ENCODED} -eq 7 ] && echo "PASS: Length is 7" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   ```

**Expected:**
- Encoded ID is exactly 7 characters
- Decoded output contains full date (2025-06-15)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Encode-Decode Roundtrip - ms Format (8 chars)

**Objective:** Verify encode/decode roundtrip works correctly for ms format (highest precision).

**Steps:**
1. Encode to ms format
   ```bash
   ENCODED=$(ace-timestamp encode --format ms -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"
   ```

2. Verify encoded ID is 8 characters
   ```bash
   [ ${#ENCODED} -eq 8 ] && echo "PASS: Length is 8" || echo "FAIL: Length is ${#ENCODED}"
   ```

3. Decode and verify
   ```bash
   DECODED=$(ace-timestamp decode -q "$ENCODED")
   echo "Decoded: $DECODED"
   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   ```

**Expected:**
- Encoded ID is exactly 8 characters
- Decoded output contains full date (2025-06-15)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Help Command Output

**Objective:** Verify help command displays available commands and usage information.

**Steps:**
1. Run help command
   ```bash
   OUTPUT=$(ace-timestamp --help 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify help content includes main commands
   ```bash
   echo "$OUTPUT" | grep -qi "encode" && echo "PASS: Shows encode command" || echo "FAIL: Missing encode"
   echo "$OUTPUT" | grep -qi "decode" && echo "PASS: Shows decode command" || echo "FAIL: Missing decode"
   ```

**Expected:**
- Output contains "encode" (case-insensitive)
- Output contains "decode" (case-insensitive)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Version Command Output

**Objective:** Verify version command displays valid semantic version.

**Steps:**
1. Run version command
   ```bash
   OUTPUT=$(ace-timestamp version 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify version format (semver)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Non-zero exit"
   echo "$OUTPUT" | grep -qE "[0-9]+\.[0-9]+\.[0-9]+" && echo "PASS: Valid semver format" || echo "FAIL: Invalid version format"
   ```

**Expected:**
- Exit code: 0
- Output matches semantic version pattern (X.Y.Z)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
# rm -rf "$TEST_DIR"
echo "Cleanup complete (directory preserved for inspection)"
```

## Success Criteria

- [ ] TC-001: Invalid ID decode returns error
- [ ] TC-002: Invalid format encode returns error
- [ ] TC-003: 2sec format (default) roundtrip works
- [ ] TC-004: Month format (2 chars) roundtrip works
- [ ] TC-005: Day format (3 chars) roundtrip works
- [ ] TC-006: Week format (3 chars) roundtrip works
- [ ] TC-007: 40min format (4 chars) roundtrip works
- [ ] TC-008: 50ms format (7 chars) roundtrip works
- [ ] TC-009: ms format (8 chars) roundtrip works
- [ ] TC-010: Help command shows encode/decode commands
- [ ] TC-011: Version command shows valid semver

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests were migrated from `cli_integration_test.rb` to improve test suite performance
- Original tests spawned Ruby subprocesses via backticks, adding ~12s to test execution
- E2E tests run separately from unit tests, keeping the fast feedback loop for development
- Format length progression: 2 (month) -> 3 (week/day) -> 4 (40min) -> 6 (2sec) -> 7 (50ms) -> 8 (ms)
