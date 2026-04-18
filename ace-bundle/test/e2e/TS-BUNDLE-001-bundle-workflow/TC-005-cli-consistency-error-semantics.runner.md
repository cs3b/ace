# Goal 5 — CLI Output Consistency and Error Semantics

## Goal

Verify CLI behavior consistency across success and error paths for the same input set:
- success path exits and output semantics stay consistent across output modes
- missing-input path returns non-zero with informative diagnostics
- comparison evidence focuses on user-visible CLI behavior only

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/cli-valid.stdout`, `.exit` — CLI output for test-context.md with `--output stdio`
- `results/tc/05/cli-valid-cache.stdout`, `.exit` — CLI output for test-context.md with `--output cache`
- `results/tc/05/comparison.md` — success-path comparison summary (`consistent` or `divergent`)
- `results/tc/05/cli-error.stdout`, `.stderr`, `.exit` — CLI output for nonexistent file

## Constraints

- Use `ace-bundle` CLI only.
- Run success path twice:
  - `ace-bundle test-context.md --output stdio`
  - `ace-bundle test-context.md --output cache`
- In `comparison.md`, classify behavior as:
  - `consistent` when both succeed and expose equivalent content semantics, or
  - `divergent` when behavior differs materially.
- Run error path:
  - `ace-bundle nonexistent-file.md --output stdio`
- Error path must be non-zero with informative output.
- All artifacts must come from real tool execution, not fabricated.
