# Goal 3 — Fix Mode End State

## Goal

Copy the `style_issues.rb` fixture to a working file, then lint it with deterministic auto-fix mode (`--auto-fix` or alias `--fix`). Prove end-state impact first (file changed), then collect report evidence.

## Workspace

Save all output to `results/tc/03/`. Capture:
- The command's stdout, stderr, and exit code
- The exact lint command contract used for this goal
- The emitted report directory path for this goal
- A diff showing the file was modified by auto-fix
- Copies of `report.json` and `fixed.md` from that exact emitted report directory when present

## Constraints

- Copy style_issues.rb to a working file (e.g., fixable.rb) before running auto-fix, to preserve the original fixture.
- `style_issues.rb` is copied into the sandbox root by setup. Use the sandbox-root file path, not `fixtures/style_issues.rb`.
- Scenario setup already installs deterministic validator shims into the sandbox runtime PATH; use the provided environment as-is.
- Using what you learned from Goal 1, invoke the fix operation. Do not assume syntax beyond what Goal 1 revealed.
- Persist the report directory emitted by the command and copy `report.json` / `fixed.md` from that directory only, so report evidence comes from the same run as the diff.
- All artifacts must come from real tool execution, not fabricated.
