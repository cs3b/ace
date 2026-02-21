---
tc-id: TC-002
title: Quiet Mode and Legacy Timestamp Format
---

## Objective

Verify that quiet mode (-q) suppresses extra output and that legacy YYYYMMDD-HHMMSS input format is accepted and treated as UTC.

## Steps

1. Verify quiet mode produces just the ID
   ```bash
   QUIET_OUTPUT=$(ace-b36ts encode -q '2025-06-15 14:32:45')
   echo "Quiet output: '$QUIET_OUTPUT'"

   if [[ "$QUIET_OUTPUT" =~ ^[0-9a-z]+$ ]]; then
     echo "PASS: Quiet output is just ID"
   else
     echo "FAIL: Extra content in quiet output"
   fi
   ```

2. Verify non-quiet has more output
   ```bash
   WITHOUT_QUIET_LINES=$(ace-b36ts encode '2025-06-15 14:32:45' 2>&1 | wc -l | tr -d ' ')
   WITH_QUIET_LINES=$(ace-b36ts encode -q '2025-06-15 14:32:45' 2>&1 | wc -l | tr -d ' ')

   echo "Without quiet: $WITHOUT_QUIET_LINES lines"
   echo "With quiet: $WITH_QUIET_LINES lines"
   if [ "$WITH_QUIET_LINES" -lt "$WITHOUT_QUIET_LINES" ]; then
     echo "PASS: Quiet reduces output"
   else
     echo "FAIL: Quiet does not reduce output"
   fi
   ```

3. Verify legacy timestamp format (YYYYMMDD-HHMMSS) produces same ID as readable format
   ```bash
   LEGACY_ID=$(ace-b36ts encode -q '20250615-143245')
   READABLE_ID=$(ace-b36ts encode -q '2025-06-15 14:32:45 UTC')

   echo "Legacy ID:   $LEGACY_ID"
   echo "Readable ID: $READABLE_ID"
   if [ "$LEGACY_ID" = "$READABLE_ID" ]; then
     echo "PASS: Legacy format accepted"
   else
     echo "FAIL: Different IDs"
   fi
   ```

## Expected

- Quiet mode (-q) produces only the compact ID (base36 characters, no headers)
- Non-quiet mode produces more output lines than quiet mode
- Legacy YYYYMMDD-HHMMSS format is treated as UTC and produces the same ID as readable UTC format
