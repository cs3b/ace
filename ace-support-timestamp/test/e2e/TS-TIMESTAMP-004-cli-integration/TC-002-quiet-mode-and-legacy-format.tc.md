---
tc-id: TC-002
title: Quiet Mode and Legacy Timestamp Format
---

## Objective

Verify that quiet mode (-q) suppresses extra output and that legacy YYYYMMDD-HHMMSS input format is accepted and treated as UTC.

## Steps

1. Verify quiet mode produces just the ID
   ```bash
   QUIET_OUTPUT=$(ace-timestamp encode -q '2025-06-15 14:32:45')
   echo "Quiet output: '$QUIET_OUTPUT'"

   [[ "$QUIET_OUTPUT" =~ ^[0-9a-z]+$ ]] && echo "PASS: Quiet output is just ID" || echo "FAIL: Extra content in quiet output"
   ```

2. Verify non-quiet has more output
   ```bash
   WITHOUT_QUIET_LINES=$(ace-timestamp encode '2025-06-15 14:32:45' 2>&1 | wc -l | tr -d ' ')
   WITH_QUIET_LINES=$(ace-timestamp encode -q '2025-06-15 14:32:45' 2>&1 | wc -l | tr -d ' ')

   echo "Without quiet: $WITHOUT_QUIET_LINES lines"
   echo "With quiet: $WITH_QUIET_LINES lines"
   [ "$WITH_QUIET_LINES" -le "$WITHOUT_QUIET_LINES" ] && echo "PASS: Quiet reduces output" || echo "FAIL: Quiet has more output"
   ```

3. Verify legacy timestamp format (YYYYMMDD-HHMMSS) produces same ID as readable format
   ```bash
   LEGACY_ID=$(ace-timestamp encode -q '20250615-143245')
   READABLE_ID=$(ace-timestamp encode -q '2025-06-15 14:32:45 UTC')

   echo "Legacy ID:   $LEGACY_ID"
   echo "Readable ID: $READABLE_ID"
   [ "$LEGACY_ID" = "$READABLE_ID" ] && echo "PASS: Legacy format accepted" || echo "FAIL: Different IDs"
   ```

## Expected

- Quiet mode (-q) produces only the compact ID (base36 characters, no headers)
- Non-quiet mode produces more output lines than quiet mode
- Legacy YYYYMMDD-HHMMSS format is treated as UTC and produces the same ID as readable UTC format
