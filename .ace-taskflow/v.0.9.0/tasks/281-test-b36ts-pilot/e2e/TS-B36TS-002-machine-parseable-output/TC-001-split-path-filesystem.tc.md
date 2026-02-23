---
tc-id: TC-001
title: Split Path Usable for Filesystem Operations
mode: goal
tags: [happy-path]
---

## Objective

Demonstrate that the ace-b36ts split output can be used directly by filesystem tools to create a date-based directory hierarchy — proving that the output format is machine-usable, not just human-readable.

## Available Tools

- `ace-b36ts` — the CLI binary under test
- Standard shell utilities: `mkdir`, `ls`, `test`, `echo`
- Shell features: command substitution `$()`, variable expansion

## Success Criteria

1. Encode a timestamp using `ace-b36ts encode` with the split format
2. Use the split output directly (via command substitution or piping) as input to `mkdir -p` to create a directory hierarchy
3. Verify the created directory path exists and has at least 2 levels of nesting
4. The directory path components should be meaningful date-based segments (not random strings)
5. No manual string manipulation (sed, awk, cut, tr) should be needed between ace-b36ts output and mkdir — the output should be directly usable

## Hints

- `ace-b36ts encode --split` produces path-like output (e.g., `YY/MM/DD`)
- The `--path-only` and `-q` flags may be useful for clean output
- Consider using `ace-b36ts encode --split --path-only -q` for filesystem-friendly output
