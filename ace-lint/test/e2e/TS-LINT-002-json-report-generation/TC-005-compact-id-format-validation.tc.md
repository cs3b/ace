---
tc-id: TC-005
title: Compact ID Format Validation
---

## Objective

Verify compact ID is valid 6-character Base36.

## Steps

1. Extract compact IDs from multiple reports and validate format
   ```bash
   rm -rf .cache/ace-lint

   ace-lint lint valid.rb > /dev/null 2>&1
   sleep 1
   ace-lint lint readme.md > /dev/null 2>&1

   ls .cache/ace-lint/

   for dir in .cache/ace-lint/*/; do
     ID=$(basename "$dir")
     if [[ "$ID" =~ ^[0-9a-z]{6}$ ]]; then
       echo "$ID - valid format"
     else
       echo "$ID - INVALID format"
     fi
   done
   ```

## Expected

- All compact IDs are exactly 6 characters
- All characters are lowercase alphanumeric (0-9, a-z)
- Each run produces a unique ID
