---
tc-id: TC-001
title: Encode-Decode Roundtrip Pipeline Through Shell
mode: procedural
tags: [smoke, happy-path]
---

## Objective

Verify that encode and decode can be chained in a shell pipeline — the output of encode feeds directly into decode without any intermediate processing, producing a timestamp that matches the original input.

## Steps

1. Pipe encode output directly into decode
   ```bash
   RESULT=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC' | xargs ace-b36ts decode -q)
   echo "Pipeline result: $RESULT"

   if echo "$RESULT" | grep -q "2025-06-15"; then
     echo "PASS: Roundtrip pipeline preserves date"
   else
     echo "FAIL: Date not preserved through pipeline"
   fi
   ```

2. Verify no trailing whitespace in encode output (would break pipes)
   ```bash
   RAW_OUTPUT=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC')
   TRIMMED=$(echo "$RAW_OUTPUT" | tr -d '[:space:]')

   echo "Raw length: ${#RAW_OUTPUT}"
   echo "Trimmed length: ${#TRIMMED}"

   if [ "${#RAW_OUTPUT}" -eq "${#TRIMMED}" ]; then
     echo "PASS: No trailing whitespace"
   else
     echo "FAIL: Trailing whitespace detected (raw=${#RAW_OUTPUT}, trimmed=${#TRIMMED})"
   fi
   ```

3. Verify command substitution roundtrip
   ```bash
   ORIGINAL_TS="2025-06-15 12:00:00 UTC"
   FINAL=$(ace-b36ts decode -q "$(ace-b36ts encode -q "$ORIGINAL_TS")")
   echo "Command substitution result: $FINAL"

   if echo "$FINAL" | grep -q "2025-06-15"; then
     echo "PASS: Command substitution roundtrip works"
   else
     echo "FAIL: Command substitution roundtrip failed"
   fi
   ```

## Expected

- `ace-b36ts encode | xargs ace-b36ts decode` produces a timestamp containing the original date
- Encode quiet output has no trailing whitespace or newline issues that break piping
- Nested command substitution `decode "$(encode ...)"` works correctly
