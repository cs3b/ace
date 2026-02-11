---
tc-id: TC-002
title: Chronological Sortability
---

## Objective

Verify that lexicographic sort order of encoded IDs equals chronological order across multiple timestamps.

## Steps

1. Encode multiple timestamps in chronological order
   ```bash
   ID1=$(ace-timestamp encode -q '2025-01-01 00:00:00')
   ID2=$(ace-timestamp encode -q '2025-03-15 06:30:00')
   ID3=$(ace-timestamp encode -q '2025-06-15 12:00:00')
   ID4=$(ace-timestamp encode -q '2025-12-31 23:59:59')

   echo "Jan 1:  $ID1"
   echo "Mar 15: $ID2"
   echo "Jun 15: $ID3"
   echo "Dec 31: $ID4"
   ```

2. Verify lexicographic order matches chronological order
   ```bash
   SORTED=$(echo -e "$ID1\n$ID2\n$ID3\n$ID4" | sort)
   EXPECTED=$(echo -e "$ID1\n$ID2\n$ID3\n$ID4")
   [ "$SORTED" = "$EXPECTED" ] && echo "PASS: Lexicographic = Chronological" || echo "FAIL: Order mismatch"
   ```

3. Verify day/week disambiguation (3-char IDs sort correctly)
   ```bash
   WEEK_ID=$(ace-timestamp encode --format week -q '2025-06-18 14:32:45')
   DAY_ID=$(ace-timestamp encode --format day -q '2025-06-18 14:32:45')
   WEEK_DECODED=$(ace-timestamp decode -q "$WEEK_ID")
   DAY_DECODED=$(ace-timestamp decode -q "$DAY_ID")

   echo "Week ID: $WEEK_ID -> $WEEK_DECODED"
   echo "Day ID:  $DAY_ID -> $DAY_DECODED"
   [ "$WEEK_DECODED" != "$DAY_DECODED" ] && echo "PASS: Week and day decode differently" || echo "FAIL: Same results"
   ```

## Expected

- Lexicographic sort produces chronological order: Jan < Mar < Jun < Dec
- Week and day formats produce different IDs for same timestamp
- Decoder correctly distinguishes between week and day formats
