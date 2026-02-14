---
tc-id: TC-003
title: Now Keyword and Decode Output Formats
---

## Objective

Verify that the "now" keyword encodes current time and that decode supports readable, iso, and timestamp output formats.

## Steps

1. Encode "now" and verify it produces a valid current-year ID
   ```bash
   NOW_ID=$(ace-b36ts encode -q now)
   echo "Encoded 'now': $NOW_ID"
   [ ${#NOW_ID} -eq 6 ] && echo "PASS: Length is 6" || echo "FAIL: Length is ${#NOW_ID}"

   DECODED_NOW=$(ace-b36ts decode -q "$NOW_ID")
   echo "Decoded: $DECODED_NOW"
   echo "$DECODED_NOW" | grep -q "$(date -u +%Y)" && echo "PASS: Current year" || echo "FAIL: Wrong year"
   ```

2. Verify decode output formats (readable, iso, timestamp)
   ```bash
   TEST_ID=$(ace-b36ts encode -q '2025-06-15 14:32:45')

   READABLE=$(ace-b36ts decode -q "$TEST_ID")
   ISO=$(ace-b36ts decode -q "$TEST_ID" --format iso)
   TIMESTAMP=$(ace-b36ts decode -q "$TEST_ID" --format timestamp)

   echo "Readable:  $READABLE"
   echo "ISO:       $ISO"
   echo "Timestamp: $TIMESTAMP"
   ```

3. Verify each format is valid
   ```bash
   echo "$READABLE" | grep -q "2025-06-15" && echo "PASS: Readable contains date" || echo "FAIL: Readable format"
   echo "$ISO" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo "PASS: ISO format valid" || echo "FAIL: ISO format invalid"
   echo "$TIMESTAMP" | grep -qE '^[0-9]{8}-[0-9]{6}$' && echo "PASS: Timestamp format valid" || echo "FAIL: Timestamp format invalid"
   ```

## Expected

- "now" keyword produces a valid 6-character ID for current time
- Decoded "now" timestamp contains the current year
- Readable format: `2025-06-15 14:32:44 UTC` (human-readable)
- ISO format: `2025-06-15T14:32:44+00:00` (ISO 8601)
- Timestamp format: `20250615-143244` (YYYYMMDD-HHMMSS)
