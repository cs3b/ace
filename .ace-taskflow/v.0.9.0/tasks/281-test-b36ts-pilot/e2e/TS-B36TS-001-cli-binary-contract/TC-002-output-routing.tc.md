---
tc-id: TC-002
title: "Output Routing: Quiet vs Verbose vs Default"
mode: procedural
tags: [happy-path]
---

## Objective

Verify that the binary correctly routes output between stdout and stderr across quiet (-q), verbose (-v), and default modes. Quiet mode should produce only the ID on stdout; verbose mode should emit config details on stderr.

## Steps

1. Verify quiet mode outputs only the ID on stdout
   ```bash
   STDOUT=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC' 2>/dev/null)
   STDERR=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC' 2>&1 1>/dev/null)

   echo "Quiet stdout: '$STDOUT'"
   echo "Quiet stderr: '$STDERR'"

   if [[ "$STDOUT" =~ ^[0-9a-z]+$ ]]; then
     echo "PASS: Quiet stdout is just the ID"
   else
     echo "FAIL: Quiet stdout has extra content"
   fi

   if [ -z "$STDERR" ]; then
     echo "PASS: Quiet stderr is empty"
   else
     echo "FAIL: Quiet stderr has content: $STDERR"
   fi
   ```

2. Verify verbose mode emits additional information on stderr
   ```bash
   VERBOSE_STDERR=$(ace-b36ts encode -v '2025-06-15 12:00:00 UTC' 2>&1 1>/dev/null)
   echo "Verbose stderr: '$VERBOSE_STDERR'"

   if [ -n "$VERBOSE_STDERR" ]; then
     echo "PASS: Verbose mode produces stderr output"
   else
     echo "FAIL: Verbose mode produces no stderr output"
   fi
   ```

3. Verify default mode stdout differs from quiet mode
   ```bash
   DEFAULT_LINES=$(ace-b36ts encode '2025-06-15 12:00:00 UTC' 2>&1 | wc -l | tr -d ' ')
   QUIET_LINES=$(ace-b36ts encode -q '2025-06-15 12:00:00 UTC' 2>&1 | wc -l | tr -d ' ')

   echo "Default lines: $DEFAULT_LINES, Quiet lines: $QUIET_LINES"

   if [ "$QUIET_LINES" -le "$DEFAULT_LINES" ]; then
     echo "PASS: Quiet mode is at most as verbose as default"
   else
     echo "FAIL: Quiet mode produces more output than default"
   fi
   ```

## Expected

- Quiet mode (-q): stdout contains only base36 ID, stderr is empty
- Verbose mode (-v): stderr contains config/debug information
- Default mode: stdout contains the ID (possibly with headers)
- Quiet mode output has fewer or equal lines compared to default mode
