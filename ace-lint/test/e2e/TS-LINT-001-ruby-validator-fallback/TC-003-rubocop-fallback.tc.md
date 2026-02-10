---
tc-id: TC-003
title: RuboCop Fallback (StandardRB Unavailable)
---

## Objective

Verify that ace-lint falls back to RuboCop when StandardRB is not available.

PATH manipulation may not work with mise shims because shims resolve executables through their own layer, bypassing PATH modifications. An alternative for mise environments is to temporarily rename the actual standardrb binary.

## Steps

1. Temporarily hide StandardRB from PATH
   ```bash
   ORIGINAL_PATH="$PATH"
   mkdir -p fake_bin
   for tool in ruby rubocop ace-lint; do
     ln -sf "$(which $tool)" fake_bin/
   done
   export PATH="$PWD/fake_bin:$PATH"
   which standardrb 2>/dev/null && echo "ERROR: standardrb still found" || echo "OK: standardrb not in PATH"
   ```

2. Run linting and verify RuboCop fallback
   ```bash
   OUTPUT=$(ace-lint lint valid.rb --verbose 2>&1)
   echo "$OUTPUT"
   echo "$OUTPUT" | grep -qi "rubocop" && echo "PASS: RuboCop was used as fallback" || echo "FAIL: No evidence of RuboCop usage in output"
   ```

3. Restore PATH
   ```bash
   export PATH="$ORIGINAL_PATH"
   ```

## Expected

- RuboCop is used instead of StandardRB
- Output or logs indicate fallback behavior
- Linting still produces results
