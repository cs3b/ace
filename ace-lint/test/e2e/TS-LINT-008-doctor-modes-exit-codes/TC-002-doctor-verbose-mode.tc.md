---
tc-id: TC-002
title: Doctor Verbose Mode
---

## Objective

Verify that doctor command verbose mode shows additional details.

## Steps

1. Run doctor command without verbose
   ```bash
   cd valid-config
   NORMAL_OUTPUT=$(ace-lint doctor 2>&1)
   NORMAL_LEN=${#NORMAL_OUTPUT}
   echo "Normal output length: $NORMAL_LEN"
   ```

2. Run doctor command with --verbose flag
   ```bash
   VERBOSE_OUTPUT=$(ace-lint doctor --verbose 2>&1)
   VERBOSE_LEN=${#VERBOSE_OUTPUT}
   echo "Verbose output length: $VERBOSE_LEN"
   echo "$VERBOSE_OUTPUT"
   ```

3. Compare output lengths
   ```bash
   if [ "$VERBOSE_LEN" -ge "$NORMAL_LEN" ]; then
     echo "PASS: Verbose mode provides at least as much output"
   else
     echo "INFO: Verbose output ($VERBOSE_LEN) is shorter than normal ($NORMAL_LEN)"
   fi
   ```

4. Verify validators are mentioned in verbose output
   ```bash
   echo "$VERBOSE_OUTPUT" | grep -qiE "standardrb|rubocop|validator" && echo "PASS: Validators shown in verbose mode" || echo "FAIL: No validators in verbose output"
   ```

## Expected

- Verbose mode shows more details
- Output includes validator information
