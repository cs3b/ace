---
tc-id: TC-002
title: Year Zero Override Encode/Decode Roundtrip
---

## Objective

Verify that year_zero override produces different IDs for the same timestamp and that decode requires matching year_zero to recover the original timestamp.

## Steps

1. Encode same timestamp with different year_zero values
   ```bash
   ID_2000=$(ace-b36ts encode -q --year-zero 2000 '2025-06-15 12:00:00')
   ID_2020=$(ace-b36ts encode -q --year-zero 2020 '2025-06-15 12:00:00')

   echo "Year zero 2000: $ID_2000"
   echo "Year zero 2020: $ID_2020"

   [ "$ID_2000" != "$ID_2020" ] && echo "PASS: Different year_zero produces different IDs" || echo "FAIL: Same IDs"
   ```

2. Decode with matching year_zero and verify correctness
   ```bash
   CORRECT=$(ace-b36ts decode -q --year-zero 2020 "$ID_2020")
   WRONG=$(ace-b36ts decode -q --year-zero 2000 "$ID_2020")

   echo "Decoded with matching year_zero=2020: $CORRECT"
   echo "Decoded with mismatched year_zero=2000: $WRONG"

   echo "$CORRECT" | grep -q "2025-06-15" && echo "PASS: Correct year_zero decodes correctly" || echo "FAIL: Decode mismatch"
   [ "$CORRECT" != "$WRONG" ] && echo "PASS: Mismatched year_zero gives different result" || echo "FAIL: Same results"
   ```

## Expected

- Same timestamp with different year_zero produces different IDs
- Matching year_zero decodes to original timestamp (2025-06-15)
- Mismatched year_zero produces a different (incorrect) timestamp
