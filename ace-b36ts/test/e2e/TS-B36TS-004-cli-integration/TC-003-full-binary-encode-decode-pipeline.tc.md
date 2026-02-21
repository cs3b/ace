---
tc-id: TC-003
title: Full Binary Encode/Decode Pipeline
---

## Objective

Verify the full end-to-end pipeline: encode a timestamp via the ace-b36ts binary, decode the result, and confirm the decoded output matches the original input within precision bounds.

## Steps

1. Encode a specific timestamp and decode it
   ```bash
   ENCODED=$(ace-b36ts encode -q '2025-06-15 12:30:45 UTC')
   echo "Encoded: $ENCODED"
   echo "Length: ${#ENCODED}"

   if [ "${#ENCODED}" -eq 6 ]; then
     echo "PASS: Default format is 6 chars"
   else
     echo "FAIL: Length is ${#ENCODED}"
   fi
   if [[ "$ENCODED" =~ ^[0-9a-z]+$ ]]; then
     echo "PASS: Valid base36"
   else
     echo "FAIL: Invalid characters"
   fi
   ```

2. Decode and verify date and approximate time
   ```bash
   DECODED=$(ace-b36ts decode -q "$ENCODED")
   echo "Decoded: $DECODED"

   if echo "$DECODED" | grep -q "2025-06-15"; then
     echo "PASS: Date matches"
   else
     echo "FAIL: Date mismatch"
   fi
   if echo "$DECODED" | grep -q "12:3"; then
     echo "PASS: Approximate time matches"
   else
     echo "FAIL: Time mismatch"
   fi
   ```

3. Verify roundtrip for month and ms formats
   ```bash
   MONTH_ENC=$(ace-b36ts encode --format month -q '2025-06-15 12:30:45 UTC')
   MONTH_DEC=$(ace-b36ts decode -q "$MONTH_ENC")
   echo "Month: $MONTH_ENC -> $MONTH_DEC"
   if echo "$MONTH_DEC" | grep -q "2025-06"; then
     echo "PASS: Month roundtrip"
   else
     echo "FAIL: Month roundtrip"
   fi

   MS_ENC=$(ace-b36ts encode --format ms -q '2025-06-15 12:30:45 UTC')
   MS_DEC=$(ace-b36ts decode -q "$MS_ENC")
   echo "ms: $MS_ENC -> $MS_DEC"
   if echo "$MS_DEC" | grep -q "2025-06-15"; then
     echo "PASS: ms roundtrip"
   else
     echo "FAIL: ms roundtrip"
   fi
   if [ "${#MS_ENC}" -eq 8 ]; then
     echo "PASS: ms is 8 chars"
   else
     echo "FAIL: ms length is ${#MS_ENC}"
   fi
   ```

## Expected

- Default encode produces 6-character base36 ID
- Decoded output contains original date (2025-06-15) and approximate time (12:3X)
- Month format: 2-char ID, decodes to 2025-06
- ms format: 8-char ID, decodes to 2025-06-15
