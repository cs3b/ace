---
tc-id: TC-003
title: Split Validation Errors
---

## Objective

Verify that the CLI rejects invalid split configurations: wrong order, missing dependencies, mutual exclusivity with --format, and unknown levels.

## Steps

1. Verify invalid split order is rejected (day,month)
   ```bash
   ace-timestamp encode --split day,month '2025-06-15 14:32:45' 2>&1
   INVALID_ORDER=$?
   echo "Invalid order exit code: $INVALID_ORDER"
   [ $INVALID_ORDER -ne 0 ] && echo "PASS: Invalid order rejected" || echo "FAIL: Should have failed"
   ```

2. Verify block without day is rejected
   ```bash
   ace-timestamp encode --split month,block '2025-06-15 14:32:45' 2>&1
   MISSING_DEP=$?
   echo "Missing dependency exit code: $MISSING_DEP"
   [ $MISSING_DEP -ne 0 ] && echo "PASS: Missing dependency rejected" || echo "FAIL: Should have failed"
   ```

3. Verify --split and --format mutual exclusivity
   ```bash
   ace-timestamp encode --split month --format day '2025-06-15 14:32:45' 2>&1
   MUTUAL=$?
   echo "Mutual exclusivity exit code: $MUTUAL"
   [ $MUTUAL -ne 0 ] && echo "PASS: Mutual exclusivity enforced" || echo "FAIL: Should have failed"
   ```

4. Verify unknown split level is rejected
   ```bash
   ace-timestamp encode --split month,invalid '2025-06-15 14:32:45' 2>&1
   UNKNOWN=$?
   echo "Unknown level exit code: $UNKNOWN"
   [ $UNKNOWN -ne 0 ] && echo "PASS: Unknown level rejected" || echo "FAIL: Should have failed"
   ```

5. Verify split must start with month
   ```bash
   ace-timestamp encode --split week,day '2025-06-15 14:32:45' 2>&1
   NO_MONTH=$?
   echo "No month start exit code: $NO_MONTH"
   [ $NO_MONTH -ne 0 ] && echo "PASS: Must start with month" || echo "FAIL: Should have failed"
   ```

## Expected

- Invalid order (day,month): non-zero exit code
- Block without day (month,block): non-zero exit code
- Split + format together: non-zero exit code
- Unknown level (month,invalid): non-zero exit code
- Not starting with month (week,day): non-zero exit code
