---
test-id: MT-TIMESTAMP-001
title: Core Encode/Decode Roundtrip
area: timestamp
package: ace-support-timestamp
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-timestamp]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Core Encode/Decode Roundtrip

## Objective

Verify that ace-timestamp correctly encodes timestamps to all 7 format precisions and decodes them back with appropriate precision loss. Tests cover format-specific characteristics including length, value ranges, and chronological sortability.

## Prerequisites

- Ruby >= 3.0 installed
- ace-timestamp CLI available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode -q)"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-ace-support-timestamp-MT-TIMESTAMP-001"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ace-timestamp && ace-timestamp version
echo "========================="
```

## Test Data

```bash
# Test timestamps spanning different scenarios
TEST_TS_CURRENT="$(date '+%Y-%m-%d %H:%M:%S')"
TEST_TS_FIXED="2025-06-15 14:32:45"
TEST_TS_MONTH_BOUNDARY="2025-01-01 00:00:00"
TEST_TS_YEAR_END="2025-12-31 23:59:59"
```

## Test Cases

### TC-001: Month Format (2 chars)

**Objective:** Verify month format produces 2-character IDs and decodes to 1st of month at midnight.

**Steps:**
1. Encode timestamp to month format
   ```bash
   MONTH_ID=$(ace-timestamp encode --format month -q '2025-06-15 14:32:45')
   echo "Month ID: $MONTH_ID"
   echo "Length: ${#MONTH_ID}"
   ```

2. Verify length is exactly 2
   ```bash
   [ ${#MONTH_ID} -eq 2 ] && echo "PASS: Length is 2" || echo "FAIL: Length is ${#MONTH_ID}"
   ```

3. Decode and verify result
   ```bash
   DECODED=$(ace-timestamp decode -q "$MONTH_ID")
   echo "Decoded: $DECODED"
   ```

4. Verify decoded is 1st of month at midnight
   ```bash
   echo "$DECODED" | grep -q '2025-06-01 00:00:00' && echo "PASS: Decodes to 1st of month" || echo "FAIL: Expected 2025-06-01 00:00:00"
   ```

**Expected:**
- Month ID is exactly 2 characters
- Decodes to `2025-06-01 00:00:00` (1st of month, midnight)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Week Format (3 chars)

**Objective:** Verify week format produces 3-character IDs with 3rd char in v-z range (31-35 in base36).

**Steps:**
1. Encode timestamp to week format
   ```bash
   WEEK_ID=$(ace-timestamp encode --format week -q '2025-06-15 14:32:45')
   echo "Week ID: $WEEK_ID"
   echo "Length: ${#WEEK_ID}"
   ```

2. Verify length is exactly 3
   ```bash
   [ ${#WEEK_ID} -eq 3 ] && echo "PASS: Length is 3" || echo "FAIL: Length is ${#WEEK_ID}"
   ```

3. Extract and verify 3rd character is in v-z range
   ```bash
   THIRD_CHAR="${WEEK_ID:2:1}"
   echo "3rd char: $THIRD_CHAR"
   [[ "$THIRD_CHAR" =~ ^[v-z]$ ]] && echo "PASS: 3rd char in v-z range" || echo "FAIL: 3rd char not in week range"
   ```

4. Decode and verify roundtrip
   ```bash
   DECODED=$(ace-timestamp decode -q "$WEEK_ID")
   echo "Decoded: $DECODED"
   ```

**Expected:**
- Week ID is exactly 3 characters
- 3rd character is in range v-z (representing weeks 0-4)
- Decodes to start of week

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Day Format (3 chars)

**Objective:** Verify day format produces 3-character IDs with 3rd char in 0-u range (0-30 in base36).

**Steps:**
1. Encode timestamp to day format
   ```bash
   DAY_ID=$(ace-timestamp encode --format day -q '2025-06-15 14:32:45')
   echo "Day ID: $DAY_ID"
   echo "Length: ${#DAY_ID}"
   ```

2. Verify length is exactly 3
   ```bash
   [ ${#DAY_ID} -eq 3 ] && echo "PASS: Length is 3" || echo "FAIL: Length is ${#DAY_ID}"
   ```

3. Extract and verify 3rd character is in 0-u range
   ```bash
   THIRD_CHAR="${DAY_ID:2:1}"
   echo "3rd char: $THIRD_CHAR"
   [[ "$THIRD_CHAR" =~ ^[0-9a-u]$ ]] && echo "PASS: 3rd char in 0-u range" || echo "FAIL: 3rd char not in day range"
   ```

4. Decode and verify roundtrip
   ```bash
   DECODED=$(ace-timestamp decode -q "$DAY_ID")
   echo "Decoded: $DECODED"
   ```

**Expected:**
- Day ID is exactly 3 characters
- 3rd character is in range 0-u (representing days 0-30)
- Decodes to start of day (midnight)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Day/Week Disambiguation

**Objective:** Verify decoder auto-detects week vs day format by examining 3rd character range.

**Steps:**
1. Encode same timestamp to both formats
   ```bash
   WEEK_ID=$(ace-timestamp encode --format week -q '2025-06-15 14:32:45')
   DAY_ID=$(ace-timestamp encode --format day -q '2025-06-15 14:32:45')
   echo "Week ID: $WEEK_ID"
   echo "Day ID: $DAY_ID"
   ```

2. Verify 3rd characters are different ranges
   ```bash
   WEEK_CHAR="${WEEK_ID:2:1}"
   DAY_CHAR="${DAY_ID:2:1}"
   echo "Week 3rd char: $WEEK_CHAR (should be v-z)"
   echo "Day 3rd char: $DAY_CHAR (should be 0-u)"
   ```

3. Decode both without specifying format
   ```bash
   WEEK_DECODED=$(ace-timestamp decode -q "$WEEK_ID")
   DAY_DECODED=$(ace-timestamp decode -q "$DAY_ID")
   echo "Week decoded: $WEEK_DECODED"
   echo "Day decoded: $DAY_DECODED"
   ```

4. Verify different results
   ```bash
   [ "$WEEK_DECODED" != "$DAY_DECODED" ] && echo "PASS: Different decode results" || echo "FAIL: Same results"
   ```

**Expected:**
- Week and day IDs both 3 characters but different 3rd char ranges
- Decoder correctly distinguishes between formats
- Week decodes to week start, day decodes to day start

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: 40min Format (4 chars)

**Objective:** Verify 40min format produces 4-character IDs and decodes to 40-minute block start.

**Steps:**
1. Encode timestamp to 40min format
   ```bash
   BLOCK_ID=$(ace-timestamp encode --format 40min -q '2025-06-15 14:32:45')
   echo "40min ID: $BLOCK_ID"
   echo "Length: ${#BLOCK_ID}"
   ```

2. Verify length is exactly 4
   ```bash
   [ ${#BLOCK_ID} -eq 4 ] && echo "PASS: Length is 4" || echo "FAIL: Length is ${#BLOCK_ID}"
   ```

3. Decode and verify block alignment
   ```bash
   DECODED=$(ace-timestamp decode -q "$BLOCK_ID")
   echo "Decoded: $DECODED"
   # 14:32 should align to 14:00 block (blocks are 0:00, 0:40, 1:20, 2:00, ...)
   ```

4. Verify minutes are 0, 40, or 20 (40-min block boundary)
   ```bash
   MINUTES=$(echo "$DECODED" | sed 's/.*:\([0-9][0-9]\):[0-9][0-9]$/\1/')
   echo "Minutes: $MINUTES"
   [[ "$MINUTES" =~ ^(00|20|40)$ ]] && echo "PASS: On 40-min boundary" || echo "FAIL: Not on boundary"
   ```

**Expected:**
- 40min ID is exactly 4 characters
- Decodes to 40-minute block start (minutes are 00, 20, or 40)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: 2sec Format (6 chars, default)

**Objective:** Verify default 2sec format produces 6-character IDs with ~1.85s precision.

**Steps:**
1. Encode timestamp to 2sec format (default)
   ```bash
   SEC_ID=$(ace-timestamp encode -q '2025-06-15 14:32:45')
   echo "2sec ID: $SEC_ID"
   echo "Length: ${#SEC_ID}"
   ```

2. Verify length is exactly 6
   ```bash
   [ ${#SEC_ID} -eq 6 ] && echo "PASS: Length is 6" || echo "FAIL: Length is ${#SEC_ID}"
   ```

3. Decode and verify roundtrip
   ```bash
   DECODED=$(ace-timestamp decode -q "$SEC_ID")
   echo "Decoded: $DECODED"
   ```

4. Verify precision loss is within ~2 seconds
   ```bash
   # Extract seconds and compare (original 45, decoded should be within 2s)
   ORIG_SEC=45
   DEC_SEC=$(echo "$DECODED" | sed 's/.*:\([0-9][0-9]\)$/\1/')
   echo "Original seconds: $ORIG_SEC, Decoded seconds: $DEC_SEC"
   DIFF=$((ORIG_SEC - DEC_SEC))
   [ ${DIFF#-} -le 2 ] && echo "PASS: Within 2-second precision" || echo "FAIL: Precision loss > 2s"
   ```

**Expected:**
- 2sec ID is exactly 6 characters (default format)
- Roundtrip precision loss is within ~1.85 seconds

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: 50ms Format (7 chars)

**Objective:** Verify 50ms format produces 7-character IDs with ~50ms precision.

**Steps:**
1. Encode timestamp to 50ms format
   ```bash
   MS50_ID=$(ace-timestamp encode --format 50ms -q '2025-06-15 14:32:45')
   echo "50ms ID: $MS50_ID"
   echo "Length: ${#MS50_ID}"
   ```

2. Verify length is exactly 7
   ```bash
   [ ${#MS50_ID} -eq 7 ] && echo "PASS: Length is 7" || echo "FAIL: Length is ${#MS50_ID}"
   ```

3. Decode and verify roundtrip
   ```bash
   DECODED=$(ace-timestamp decode -q "$MS50_ID")
   echo "Decoded: $DECODED"
   ```

**Expected:**
- 50ms ID is exactly 7 characters
- Supports sub-second precision (~50ms)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: ms Format (8 chars)

**Objective:** Verify ms format produces 8-character IDs with ~1.4ms precision.

**Steps:**
1. Encode timestamp to ms format
   ```bash
   MS_ID=$(ace-timestamp encode --format ms -q '2025-06-15 14:32:45')
   echo "ms ID: $MS_ID"
   echo "Length: ${#MS_ID}"
   ```

2. Verify length is exactly 8
   ```bash
   [ ${#MS_ID} -eq 8 ] && echo "PASS: Length is 8" || echo "FAIL: Length is ${#MS_ID}"
   ```

3. Decode and verify roundtrip
   ```bash
   DECODED=$(ace-timestamp decode -q "$MS_ID")
   echo "Decoded: $DECODED"
   ```

**Expected:**
- ms ID is exactly 8 characters
- Supports highest precision (~1.4ms)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Chronological Sortability

**Objective:** Verify that lexicographic sort order equals chronological order.

**Steps:**
1. Encode multiple timestamps in random order
   ```bash
   ID1=$(ace-timestamp encode -q '2025-01-01 00:00:00')
   ID2=$(ace-timestamp encode -q '2025-06-15 12:00:00')
   ID3=$(ace-timestamp encode -q '2025-12-31 23:59:59')
   ID4=$(ace-timestamp encode -q '2025-03-15 06:30:00')
   echo "Jan 1: $ID1"
   echo "Jun 15: $ID2"
   echo "Dec 31: $ID3"
   echo "Mar 15: $ID4"
   ```

2. Sort lexicographically
   ```bash
   SORTED=$(echo -e "$ID1\n$ID2\n$ID3\n$ID4" | sort)
   echo "Sorted order:"
   echo "$SORTED"
   ```

3. Verify chronological order
   ```bash
   EXPECTED=$(echo -e "$ID1\n$ID4\n$ID2\n$ID3")
   [ "$SORTED" = "$EXPECTED" ] && echo "PASS: Lexicographic = Chronological" || echo "FAIL: Order mismatch"
   ```

**Expected:**
- Lexicographic sort produces chronological order: Jan < Mar < Jun < Dec

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: "now" Keyword

**Objective:** Verify that "now" keyword encodes current time.

**Steps:**
1. Record current time and encode "now"
   ```bash
   BEFORE=$(date +%s)
   NOW_ID=$(ace-timestamp encode -q now)
   AFTER=$(date +%s)
   echo "Encoded 'now': $NOW_ID"
   ```

2. Decode and convert to epoch
   ```bash
   DECODED=$(ace-timestamp decode -q "$NOW_ID" --format iso)
   echo "Decoded: $DECODED"
   ```

3. Verify decoded time is between before and after
   ```bash
   # Just verify it decodes successfully and is recent
   echo "$DECODED" | grep -q "$(date +%Y)" && echo "PASS: Current year" || echo "FAIL: Wrong year"
   ```

**Expected:**
- "now" keyword produces valid ID for current time
- Decoded time is within a few seconds of current time

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Decode Output Formats

**Objective:** Verify decode supports readable, iso, and timestamp output formats.

**Steps:**
1. Encode a test timestamp
   ```bash
   TEST_ID=$(ace-timestamp encode -q '2025-06-15 14:32:45')
   echo "Test ID: $TEST_ID"
   ```

2. Decode with readable format (default)
   ```bash
   READABLE=$(ace-timestamp decode -q "$TEST_ID")
   echo "Readable: $READABLE"
   ```

3. Decode with ISO format
   ```bash
   ISO=$(ace-timestamp decode -q "$TEST_ID" --format iso)
   echo "ISO: $ISO"
   ```

4. Decode with timestamp format
   ```bash
   TIMESTAMP=$(ace-timestamp decode -q "$TEST_ID" --format timestamp)
   echo "Timestamp: $TIMESTAMP"
   ```

5. Verify formats are different and valid
   ```bash
   [[ "$ISO" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]] && echo "PASS: ISO format valid" || echo "FAIL: ISO format invalid"
   [[ "$TIMESTAMP" =~ ^[0-9]{8}-[0-9]{6}$ ]] && echo "PASS: Timestamp format valid" || echo "FAIL: Timestamp format invalid"
   ```

**Expected:**
- Readable: `2025-06-15 14:32:44` (human-readable)
- ISO: `2025-06-15T14:32:44+00:00` (ISO 8601)
- Timestamp: `20250615-143244` (YYYYMMDD-HHMMSS)

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

- [ ] TC-001: Month format produces 2-char IDs
- [ ] TC-002: Week format produces 3-char IDs with v-z 3rd char
- [ ] TC-003: Day format produces 3-char IDs with 0-u 3rd char
- [ ] TC-004: Day/week disambiguation works correctly
- [ ] TC-005: 40min format produces 4-char IDs
- [ ] TC-006: 2sec format (default) produces 6-char IDs
- [ ] TC-007: 50ms format produces 7-char IDs
- [ ] TC-008: ms format produces 8-char IDs
- [ ] TC-009: Lexicographic sort = chronological order
- [ ] TC-010: "now" keyword encodes current time
- [ ] TC-011: All decode output formats work correctly

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Format length progression: 2 (month) -> 3 (week/day) -> 4 (40min) -> 6 (2sec) -> 7 (50ms) -> 8 (ms)
- Week vs day disambiguation relies on 3rd character range (v-z vs 0-u)
- Default format is 2sec (6 chars) - optimal balance of precision and compactness
- All formats maintain chronological sortability
