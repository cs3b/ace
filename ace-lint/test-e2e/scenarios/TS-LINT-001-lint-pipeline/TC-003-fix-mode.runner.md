# Goal 3 — Fix Mode

## Goal

Copy the `style_issues.rb` fixture to a working file, then lint it with deterministic auto-fix mode (`--auto-fix` or alias `--fix`). Capture evidence that the file was modified and that a fixed.md report was generated.

## Workspace

Save all output to `results/tc/03/`. Capture:
- The command's stdout, stderr, and exit code
- A diff showing the file was modified by auto-fix
- A copy of the generated fixed.md
- The summary.fixed count from report.json

## Constraints

- Copy style_issues.rb to a working file (e.g., fixable.rb) before running auto-fix, to preserve the original fixture.
- Using what you learned from Goal 1, invoke the fix operation. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
