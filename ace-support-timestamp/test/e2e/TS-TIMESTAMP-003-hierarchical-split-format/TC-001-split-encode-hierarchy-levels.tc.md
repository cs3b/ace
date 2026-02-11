---
tc-id: TC-001
title: Split Encode at Multiple Hierarchy Levels
---

## Objective

Verify that split encoding produces correct hierarchical path components for month, month+week, month+day, and month+week+day+block levels.

## Steps

1. Encode with month-only split
   ```bash
   TS="2025-06-15 14:32:45"

   MONTH_PATH=$(ace-timestamp encode --split month --path-only -q "$TS")
   echo "month split: $MONTH_PATH"
   echo "$MONTH_PATH" | grep -q "/" && echo "PASS: Path has separator" || echo "FAIL: No separator"
   ```

2. Encode with month,week and month,day splits
   ```bash
   MW_PATH=$(ace-timestamp encode --split month,week --path-only -q "$TS")
   MD_PATH=$(ace-timestamp encode --split month,day --path-only -q "$TS")

   echo "month,week split: $MW_PATH"
   echo "month,day split:  $MD_PATH"

   MW_PARTS=$(echo "$MW_PATH" | tr '/' '\n' | wc -l)
   MD_PARTS=$(echo "$MD_PATH" | tr '/' '\n' | wc -l)
   [ "$MW_PARTS" -eq 3 ] && echo "PASS: month,week has 3 parts" || echo "FAIL: Expected 3 parts, got $MW_PARTS"
   [ "$MD_PARTS" -eq 3 ] && echo "PASS: month,day has 3 parts" || echo "FAIL: Expected 3 parts, got $MD_PARTS"
   ```

3. Encode with full hierarchy month,week,day,block
   ```bash
   FULL_PATH=$(ace-timestamp encode --split month,week,day,block --path-only -q "$TS")
   echo "Full split: $FULL_PATH"

   FULL_PARTS=$(echo "$FULL_PATH" | tr '/' '\n' | wc -l)
   [ "$FULL_PARTS" -eq 5 ] && echo "PASS: Full hierarchy has 5 parts" || echo "FAIL: Expected 5 parts, got $FULL_PARTS"
   ```

4. Verify split roundtrip preserves timestamp
   ```bash
   ORIGINAL_ID=$(ace-timestamp encode -q "$TS")
   SPLIT_PATH=$(ace-timestamp encode --split month,week,day --path-only -q "$TS")
   DECODED_SPLIT=$(ace-timestamp decode -q "$SPLIT_PATH")
   DECODED_ORIG=$(ace-timestamp decode -q "$ORIGINAL_ID")

   echo "Original decoded: $DECODED_ORIG"
   echo "Split decoded:    $DECODED_SPLIT"
   [ "$DECODED_SPLIT" = "$DECODED_ORIG" ] && echo "PASS: Roundtrip successful" || echo "FAIL: Different timestamps"
   ```

## Expected

- Month-only split: path with 2 parts (month/rest)
- Month,week and month,day splits: paths with 3 parts
- Full hierarchy: path with 5 parts (month/week/day/block/rest)
- Split path decodes to same timestamp as original flat ID
