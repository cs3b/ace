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

   [ ${#ENCODED} -eq 6 ] && echo "PASS: Default format is 6 chars" || echo "FAIL: Length is ${#ENCODED}"
   [[ "$ENCODED" =~ ^[0-9a-z]+$ ]] && echo "PASS: Valid base36" || echo "FAIL: Invalid characters"
   ```

2. Decode and verify date and approximate time
   ```bash
   DECODED=$(ace-b36ts decode -q "$ENCODED")
   echo "Decoded: $DECODED"

   echo "$DECODED" | grep -q "2025-06-15" && echo "PASS: Date matches" || echo "FAIL: Date mismatch"
   echo "$DECODED" | grep -q "12:3" && echo "PASS: Approximate time matches" || echo "FAIL: Time mismatch"
   ```

3. Verify roundtrip for month and ms formats
   ```bash
   MONTH_ENC=$(ace-b36ts encode --format month -q '2025-06-15 12:30:45 UTC')
   MONTH_DEC=$(ace-b36ts decode -q "$MONTH_ENC")
   echo "Month: $MONTH_ENC -> $MONTH_DEC"
   echo "$MONTH_DEC" | grep -q "2025-06" && echo "PASS: Month roundtrip" || echo "FAIL: Month roundtrip"

   MS_ENC=$(ace-b36ts encode --format ms -q '2025-06-15 12:30:45 UTC')
   MS_DEC=$(ace-b36ts decode -q "$MS_ENC")
   echo "ms: $MS_ENC -> $MS_DEC"
   echo "$MS_DEC" | grep -q "2025-06-15" && echo "PASS: ms roundtrip" || echo "FAIL: ms roundtrip"
   [ ${#MS_ENC} -eq 8 ] && echo "PASS: ms is 8 chars" || echo "FAIL: ms length is ${#MS_ENC}"
   ```

## Expected

- Default encode produces 6-character base36 ID
- Decoded output contains original date (2025-06-15) and approximate time (12:3X)
- Month format: 2-char ID, decodes to 2025-06
- ms format: 8-char ID, decodes to 2025-06-15
