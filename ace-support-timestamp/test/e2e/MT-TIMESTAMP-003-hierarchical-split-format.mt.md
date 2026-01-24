---
test-id: MT-TIMESTAMP-003
title: Hierarchical Split Format
area: timestamp
package: ace-support-timestamp
priority: medium
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-timestamp]
  ruby: ">= 3.0"
status: ready-for-execution
last-verified: 2026-01-24
verified-by: code-review
---

# Hierarchical Split Format

## Objective

Verify that ace-timestamp correctly handles hierarchical split encoding and decoding. The split format breaks a timestamp into hierarchical components (month, week, day, block) for use in file paths and directory structures.

## Prerequisites

- Ruby >= 3.0 installed
- ace-timestamp CLI available in PATH
- **Task 225.02 completed** (hierarchical split format implementation)

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TEST_ID="$(ace-timestamp encode -q)"
TEST_DIR="$PROJECT_ROOT/.cache/test-e2e/${TEST_ID}-timestamp-split"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ace-timestamp && ace-timestamp version
echo "========================="
```

## Test Data

```bash
# Test timestamp for consistent results
TEST_TS="2025-06-15 14:32:45"
```

## Test Cases

### TC-001: Split with Month Only

**Objective:** Verify split with just month level produces month prefix and remainder.

**Steps:**
1. Encode with month split
   ```bash
   ace-timestamp encode --split month -q "$TEST_TS"
   ```

2. Verify output structure
   ```bash
   OUTPUT=$(ace-timestamp encode --split month "$TEST_TS")
   echo "$OUTPUT"
   # Expected: month component + rest
   ```

3. Verify path format
   ```bash
   ace-timestamp encode --split month --path-only -q "$TEST_TS"
   ```

**Expected:**
- Output shows month component separated from remainder
- Path format: `{month}/{rest}` (e.g., `i5/0ejj3`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Split with Month,Week

**Objective:** Verify split with month and week levels produces hierarchical components.

**Steps:**
1. Encode with month,week split
   ```bash
   ace-timestamp encode --split month,week -q "$TEST_TS"
   ```

2. Verify hierarchical output
   ```bash
   OUTPUT=$(ace-timestamp encode --split month,week "$TEST_TS")
   echo "$OUTPUT"
   ```

3. Verify path format
   ```bash
   ace-timestamp encode --split month,week --path-only -q "$TEST_TS"
   ```

**Expected:**
- Output shows month and week components
- Path format: `{month}/{week}/{rest}` (e.g., `i5/2/jj3`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Split with Month,Day

**Objective:** Verify split can skip week and go directly to day level.

**Steps:**
1. Encode with month,day split (skipping week)
   ```bash
   ace-timestamp encode --split month,day -q "$TEST_TS"
   ```

2. Verify output
   ```bash
   OUTPUT=$(ace-timestamp encode --split month,day "$TEST_TS")
   echo "$OUTPUT"
   ```

3. Verify path format
   ```bash
   ace-timestamp encode --split month,day --path-only -q "$TEST_TS"
   ```

**Expected:**
- Output shows month and day components (week skipped)
- Path format: `{month}/{day}/{rest}` (e.g., `i5/e/jj3`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Split with Month,Week,Day

**Objective:** Verify full month,week,day hierarchy.

**Steps:**
1. Encode with full hierarchy
   ```bash
   ace-timestamp encode --split month,week,day -q "$TEST_TS"
   ```

2. Verify output
   ```bash
   OUTPUT=$(ace-timestamp encode --split month,week,day "$TEST_TS")
   echo "$OUTPUT"
   ```

3. Verify path format
   ```bash
   ace-timestamp encode --split month,week,day --path-only -q "$TEST_TS"
   ```

**Expected:**
- Output shows month, week, and day components
- Path format: `{month}/{week}/{day}/{rest}` (e.g., `i5/2/e/jj3`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Split with Month,Week,Day,Block

**Objective:** Verify deepest hierarchy including 40min block.

**Steps:**
1. Encode with full hierarchy including block
   ```bash
   ace-timestamp encode --split month,week,day,block -q "$TEST_TS"
   ```

2. Verify output
   ```bash
   OUTPUT=$(ace-timestamp encode --split month,week,day,block "$TEST_TS")
   echo "$OUTPUT"
   ```

3. Verify path format
   ```bash
   ace-timestamp encode --split month,week,day,block --path-only -q "$TEST_TS"
   ```

**Expected:**
- Output shows all hierarchical components
- Path format: `{month}/{week}/{day}/{block}/{rest}` (e.g., `i5/2/e/j/j3`)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: --path-only Output

**Objective:** Verify path-only mode outputs single line suitable for shell scripts.

**Steps:**
1. Get path-only output
   ```bash
   PATH_ONLY=$(ace-timestamp encode --split month,week --path-only -q "$TEST_TS")
   echo "Path: $PATH_ONLY"
   ```

2. Verify single line
   ```bash
   LINE_COUNT=$(echo "$PATH_ONLY" | wc -l)
   [ "$LINE_COUNT" -eq 1 ] && echo "PASS: Single line" || echo "FAIL: Multiple lines"
   ```

3. Verify usable in shell
   ```bash
   mkdir -p "$TEST_DIR/$PATH_ONLY"
   [ -d "$TEST_DIR/$PATH_ONLY" ] && echo "PASS: Valid path" || echo "FAIL: Invalid path"
   ```

**Expected:**
- Output is single line with path separators
- Path can be used directly in mkdir/file operations

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: --json Output

**Objective:** Verify JSON output mode produces valid JSON structure.

**Steps:**
1. Get JSON output
   ```bash
   JSON_OUT=$(ace-timestamp encode --split month,week,day --json -q "$TEST_TS")
   echo "$JSON_OUT"
   ```

2. Verify valid JSON
   ```bash
   echo "$JSON_OUT" | jq . > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
   ```

3. Verify structure contains expected keys
   ```bash
   echo "$JSON_OUT" | jq -e '.month' > /dev/null && echo "PASS: Has month key" || echo "FAIL: Missing month"
   echo "$JSON_OUT" | jq -e '.path' > /dev/null && echo "PASS: Has path key" || echo "FAIL: Missing path"
   ```

**Expected:**
- Output is valid JSON
- Contains component keys (month, week, day, etc.)
- Contains assembled path

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Decode from Path

**Objective:** Verify decode auto-detects path separators (/, \, :).

**Steps:**
1. Encode to get path
   ```bash
   PATH_ID=$(ace-timestamp encode --split month,week,day --path-only -q "$TEST_TS")
   echo "Path: $PATH_ID"
   ```

2. Decode from forward-slash path
   ```bash
   DECODED_SLASH=$(ace-timestamp decode -q "$PATH_ID")
   echo "Decoded /: $DECODED_SLASH"
   ```

3. Convert to backslash and decode
   ```bash
   BACKSLASH_PATH=$(echo "$PATH_ID" | tr '/' '\\')
   DECODED_BACK=$(ace-timestamp decode -q "$BACKSLASH_PATH")
   echo "Decoded \\: $DECODED_BACK"
   ```

4. Convert to colon and decode
   ```bash
   COLON_PATH=$(echo "$PATH_ID" | tr '/' ':')
   DECODED_COLON=$(ace-timestamp decode -q "$COLON_PATH")
   echo "Decoded :: $DECODED_COLON"
   ```

5. Verify all decode to same result
   ```bash
   [ "$DECODED_SLASH" = "$DECODED_BACK" ] && [ "$DECODED_BACK" = "$DECODED_COLON" ] && echo "PASS: All separators work" || echo "FAIL: Different results"
   ```

**Expected:**
- Forward slash (/) path decodes correctly
- Backslash (\) path decodes correctly
- Colon (:) path decodes correctly
- All produce same timestamp

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Split Roundtrip

**Objective:** Verify encode to split path and back decodes to original time.

**Steps:**
1. Encode original timestamp
   ```bash
   ORIGINAL_ID=$(ace-timestamp encode -q "$TEST_TS")
   echo "Original ID: $ORIGINAL_ID"
   ```

2. Encode with split
   ```bash
   SPLIT_PATH=$(ace-timestamp encode --split month,week,day --path-only -q "$TEST_TS")
   echo "Split path: $SPLIT_PATH"
   ```

3. Decode split path
   ```bash
   DECODED_TS=$(ace-timestamp decode -q "$SPLIT_PATH")
   echo "Decoded: $DECODED_TS"
   ```

4. Decode original for comparison
   ```bash
   ORIGINAL_TS=$(ace-timestamp decode -q "$ORIGINAL_ID")
   echo "Original decoded: $ORIGINAL_TS"
   ```

5. Verify same timestamp
   ```bash
   [ "$DECODED_TS" = "$ORIGINAL_TS" ] && echo "PASS: Roundtrip successful" || echo "FAIL: Different timestamps"
   ```

**Expected:**
- Split path decodes to same timestamp as original ID
- No information loss in split/unsplit roundtrip

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Invalid Split Order

**Objective:** Verify CLI rejects invalid split level ordering (e.g., day,month).

**Steps:**
1. Try invalid order: day,month
   ```bash
   ace-timestamp encode --split day,month "$TEST_TS" 2>&1
   RESULT=$?
   echo "Exit code: $RESULT"
   ```

2. Verify error
   ```bash
   [ $RESULT -ne 0 ] && echo "PASS: Invalid order rejected" || echo "FAIL: Should have failed"
   ```

3. Verify error message is helpful
   ```bash
   ace-timestamp encode --split day,month "$TEST_TS" 2>&1 | grep -qi "order\|invalid\|must\|error" && echo "PASS: Error message present" || echo "CHECK: Review error"
   ```

**Expected:**
- Non-zero exit code
- Error message indicates invalid ordering
- May suggest correct order

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Block Without Day

**Objective:** Verify CLI rejects block level without day (dependency error).

**Steps:**
1. Try block without day: month,block
   ```bash
   ace-timestamp encode --split month,block "$TEST_TS" 2>&1
   RESULT=$?
   echo "Exit code: $RESULT"
   ```

2. Verify error
   ```bash
   [ $RESULT -ne 0 ] && echo "PASS: Missing dependency rejected" || echo "FAIL: Should have failed"
   ```

3. Verify error message mentions dependency
   ```bash
   ace-timestamp encode --split month,block "$TEST_TS" 2>&1 | grep -qi "require\|depend\|day\|error" && echo "PASS: Dependency error shown" || echo "CHECK: Review error"
   ```

**Expected:**
- Non-zero exit code
- Error indicates block requires day level
- Suggests including day in split levels

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-012: Split + Format Mutual Exclusivity

**Objective:** Verify CLI rejects both --split and --format options together.

**Steps:**
1. Try both options
   ```bash
   ace-timestamp encode --split month --format day "$TEST_TS" 2>&1
   RESULT=$?
   echo "Exit code: $RESULT"
   ```

2. Verify error
   ```bash
   [ $RESULT -ne 0 ] && echo "PASS: Mutual exclusivity enforced" || echo "FAIL: Should have failed"
   ```

3. Verify error message
   ```bash
   ace-timestamp encode --split month --format day "$TEST_TS" 2>&1 | grep -qi "mutual\|exclusive\|both\|cannot\|error" && echo "PASS: Error message present" || echo "CHECK: Review error"
   ```

**Expected:**
- Non-zero exit code
- Error indicates --split and --format cannot be used together
- Clear guidance on which to use

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-013: Unknown Split Level

**Objective:** Verify CLI rejects unknown split level names.

**Steps:**
1. Try unknown level
   ```bash
   ace-timestamp encode --split month,invalid "$TEST_TS" 2>&1
   RESULT=$?
   echo "Exit code: $RESULT"
   ```

2. Verify error
   ```bash
   [ $RESULT -ne 0 ] && echo "PASS: Unknown level rejected" || echo "FAIL: Should have failed"
   ```

3. Verify suggestions provided
   ```bash
   ace-timestamp encode --split month,invalid "$TEST_TS" 2>&1 | grep -qi "week\|day\|block\|valid\|error" && echo "PASS: Suggests valid levels" || echo "CHECK: Review error"
   ```

**Expected:**
- Non-zero exit code
- Error identifies unknown level
- Suggests valid level names (week, day, block)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-014: Split Must Start with Month

**Objective:** Verify CLI requires month as first split level.

**Steps:**
1. Try starting with week
   ```bash
   ace-timestamp encode --split week,day "$TEST_TS" 2>&1
   RESULT=$?
   echo "Exit code: $RESULT"
   ```

2. Try starting with day
   ```bash
   ace-timestamp encode --split day "$TEST_TS" 2>&1
   DAY_RESULT=$?
   ```

3. Verify both fail
   ```bash
   [ $RESULT -ne 0 ] && [ $DAY_RESULT -ne 0 ] && echo "PASS: Must start with month" || echo "FAIL: Should require month first"
   ```

4. Verify error message
   ```bash
   ace-timestamp encode --split week,day "$TEST_TS" 2>&1 | grep -qi "month\|start\|first\|error" && echo "PASS: Error mentions month" || echo "CHECK: Review error"
   ```

**Expected:**
- Non-zero exit code for split not starting with month
- Error message indicates month must be first level

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

- [ ] TC-001: Split with month only works
- [ ] TC-002: Split with month,week works
- [ ] TC-003: Split with month,day (skip week) works
- [ ] TC-004: Split with month,week,day works
- [ ] TC-005: Split with month,week,day,block works
- [ ] TC-006: --path-only outputs single usable line
- [ ] TC-007: --json outputs valid JSON structure
- [ ] TC-008: Decode auto-detects path separators
- [ ] TC-009: Split encode/decode roundtrip preserves timestamp
- [ ] TC-010: Invalid split order rejected
- [ ] TC-011: Block without day rejected
- [ ] TC-012: Split + format mutual exclusivity enforced
- [ ] TC-013: Unknown split level rejected with suggestions
- [ ] TC-014: Split must start with month

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Split format is designed for hierarchical file storage (e.g., archive directories)
- Hierarchy levels: month -> week -> day -> block (40min)
- Path separators auto-detected: /, \, : for cross-platform compatibility
- JSON output useful for programmatic processing
- Week can be skipped (month,day is valid)
- Block requires day (cannot use month,block)
