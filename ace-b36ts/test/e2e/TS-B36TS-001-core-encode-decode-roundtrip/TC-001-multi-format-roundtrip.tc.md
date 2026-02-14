---
tc-id: TC-001
title: Multi-Format Encode/Decode Roundtrip
---

## Objective

Verify that ace-b36ts CLI correctly encodes a timestamp to all 7 format precisions and decodes them back, producing IDs of the expected character lengths.

## Steps

1. Encode a fixed timestamp to all 7 formats and verify ID lengths
   ```bash
   TS="2025-06-15 14:32:45"

   MONTH_ID=$(ace-b36ts encode --format month -q "$TS")
   WEEK_ID=$(ace-b36ts encode --format week -q "$TS")
   DAY_ID=$(ace-b36ts encode --format day -q "$TS")
   MIN40_ID=$(ace-b36ts encode --format 40min -q "$TS")
   SEC2_ID=$(ace-b36ts encode -q "$TS")
   MS50_ID=$(ace-b36ts encode --format 50ms -q "$TS")
   MS_ID=$(ace-b36ts encode --format ms -q "$TS")

   echo "month:  $MONTH_ID (${#MONTH_ID} chars)"
   echo "week:   $WEEK_ID (${#WEEK_ID} chars)"
   echo "day:    $DAY_ID (${#DAY_ID} chars)"
   echo "40min:  $MIN40_ID (${#MIN40_ID} chars)"
   echo "2sec:   $SEC2_ID (${#SEC2_ID} chars)"
   echo "50ms:   $MS50_ID (${#MS50_ID} chars)"
   echo "ms:     $MS_ID (${#MS_ID} chars)"
   ```

2. Verify each ID has the correct length
   ```bash
   [ ${#MONTH_ID} -eq 2 ] && echo "PASS: month=2" || echo "FAIL: month=${#MONTH_ID}"
   [ ${#WEEK_ID} -eq 3 ] && echo "PASS: week=3" || echo "FAIL: week=${#WEEK_ID}"
   [ ${#DAY_ID} -eq 3 ] && echo "PASS: day=3" || echo "FAIL: day=${#DAY_ID}"
   [ ${#MIN40_ID} -eq 4 ] && echo "PASS: 40min=4" || echo "FAIL: 40min=${#MIN40_ID}"
   [ ${#SEC2_ID} -eq 6 ] && echo "PASS: 2sec=6" || echo "FAIL: 2sec=${#SEC2_ID}"
   [ ${#MS50_ID} -eq 7 ] && echo "PASS: 50ms=7" || echo "FAIL: 50ms=${#MS50_ID}"
   [ ${#MS_ID} -eq 8 ] && echo "PASS: ms=8" || echo "FAIL: ms=${#MS_ID}"
   ```

3. Decode each format and verify date preservation
   ```bash
   DECODED_MONTH=$(ace-b36ts decode -q "$MONTH_ID")
   DECODED_DAY=$(ace-b36ts decode -q "$DAY_ID")
   DECODED_SEC2=$(ace-b36ts decode -q "$SEC2_ID")
   DECODED_MS=$(ace-b36ts decode -q "$MS_ID")

   echo "$DECODED_MONTH" | grep -q "2025-06" && echo "PASS: month decodes to 2025-06" || echo "FAIL: month decode mismatch"
   echo "$DECODED_DAY" | grep -q "2025-06-15" && echo "PASS: day decodes to 2025-06-15" || echo "FAIL: day decode mismatch"
   echo "$DECODED_SEC2" | grep -q "2025-06-15" && echo "PASS: 2sec decodes to 2025-06-15" || echo "FAIL: 2sec decode mismatch"
   echo "$DECODED_MS" | grep -q "2025-06-15" && echo "PASS: ms decodes to 2025-06-15" || echo "FAIL: ms decode mismatch"
   ```

## Expected

- Format lengths: month=2, week=3, day=3, 40min=4, 2sec=6, 50ms=7, ms=8
- All IDs contain only base36 characters (0-9a-z)
- Decoded timestamps preserve the original date (2025-06-15)
- Month format decodes to first of month (2025-06-01)
