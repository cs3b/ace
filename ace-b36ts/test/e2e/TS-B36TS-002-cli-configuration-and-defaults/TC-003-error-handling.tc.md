---
tc-id: TC-003
title: Error Handling for Invalid Inputs
---

## Objective

Verify that the CLI rejects invalid format names, invalid compact IDs, and out-of-range timestamps with non-zero exit codes and helpful error messages.

## Steps

1. Verify invalid format name is rejected
   ```bash
   ace-b36ts encode --format invalid '2025-06-15' 2>&1
   INVALID_FORMAT=$?
   echo "Invalid format exit code: $INVALID_FORMAT"
   [ $INVALID_FORMAT -ne 0 ] && echo "PASS: Invalid format rejected" || echo "FAIL: Should have failed"
   ```

2. Verify invalid compact IDs are rejected
   ```bash
   ace-b36ts decode '!@#$%' 2>&1
   INVALID_CHAR=$?

   ace-b36ts decode 'a' 2>&1
   TOO_SHORT=$?

   ace-b36ts decode 'abcdefghij' 2>&1
   TOO_LONG=$?

   echo "Invalid chars: $INVALID_CHAR, Too short: $TOO_SHORT, Too long: $TOO_LONG"
   [ $INVALID_CHAR -ne 0 ] && [ $TOO_SHORT -ne 0 ] && [ $TOO_LONG -ne 0 ] && echo "PASS: All invalid IDs rejected" || echo "FAIL: Some invalid IDs accepted"
   ```

3. Verify out-of-range timestamps are rejected
   ```bash
   ace-b36ts encode -q '1999-01-01 00:00:00' 2>&1
   BEFORE_RANGE=$?

   ace-b36ts encode -q '2109-01-01 00:00:00' 2>&1
   AFTER_RANGE=$?

   echo "Before range: $BEFORE_RANGE, After range: $AFTER_RANGE"
   [ $BEFORE_RANGE -ne 0 ] && [ $AFTER_RANGE -ne 0 ] && echo "PASS: Out-of-range rejected" || echo "FAIL: Out-of-range accepted"
   ```

## Expected

- Invalid format name: non-zero exit code with error message
- Invalid characters in ID: non-zero exit code
- Too short ID (1 char): non-zero exit code
- Too long ID (10 chars): non-zero exit code
- Year before year_zero (1999): non-zero exit code
- Year after year_zero + 108 (2109): non-zero exit code
