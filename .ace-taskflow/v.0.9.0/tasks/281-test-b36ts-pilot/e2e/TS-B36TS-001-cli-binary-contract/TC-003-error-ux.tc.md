---
tc-id: TC-003
title: "Error UX: Exit Codes and Stderr Messages"
mode: procedural
tags: [happy-path]
---

## Objective

Verify the full error UX path: invalid input → exception in Ruby → user-friendly message on stderr → non-zero exit code. This tests that errors are surfaced correctly through the binary wrapper, not swallowed or stack-traced.

## Steps

1. Verify invalid format name produces non-zero exit and stderr message
   ```bash
   STDERR=$(ace-b36ts encode --format invalid '2025-06-15' 2>&1 1>/dev/null)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Stderr: $STDERR"

   [ $EXIT_CODE -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Exit code was 0"
   [ -n "$STDERR" ] && echo "PASS: Stderr has error message" || echo "FAIL: No error message"
   ```

2. Verify invalid decode input produces non-zero exit and stderr message
   ```bash
   STDERR=$(ace-b36ts decode '!@#$%' 2>&1 1>/dev/null)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Stderr: $STDERR"

   [ $EXIT_CODE -ne 0 ] && echo "PASS: Invalid chars rejected" || echo "FAIL: Invalid chars accepted"
   [ -n "$STDERR" ] && echo "PASS: Stderr has error message" || echo "FAIL: No error message"
   ```

3. Verify error messages go to stderr (not stdout)
   ```bash
   STDOUT=$(ace-b36ts encode --format invalid '2025-06-15' 2>/dev/null)
   STDERR=$(ace-b36ts encode --format invalid '2025-06-15' 2>&1 1>/dev/null)

   echo "Stdout on error: '$STDOUT'"
   echo "Stderr on error: '$STDERR'"

   if [ -z "$STDOUT" ] && [ -n "$STDERR" ]; then
     echo "PASS: Error goes to stderr only"
   else
     echo "FAIL: Error routing incorrect (stdout='$STDOUT', stderr='$STDERR')"
   fi
   ```

## Expected

- Invalid format: non-zero exit code, error message on stderr, nothing on stdout
- Invalid decode input: non-zero exit code, error message on stderr
- All error messages route to stderr (fd 2), stdout (fd 1) is clean on error
