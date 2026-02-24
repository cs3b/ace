# Goal 4 — Error Detection

## Goal

Lint the `syntax_error.rb` fixture and verify the tool correctly reports the syntax error with a non-zero exit code and generates a pending.md report with checkbox-format issues.

## Workspace

Save all output to `results/tc/04/`. Capture:
- The command's stdout, stderr, and exit code
- A copy of the generated pending.md

## Constraints

- Using what you learned from Goal 1, invoke the lint operation on syntax_error.rb.
- All artifacts must come from real tool execution, not fabricated.
