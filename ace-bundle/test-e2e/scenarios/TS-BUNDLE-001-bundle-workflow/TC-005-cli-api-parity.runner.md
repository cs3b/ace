# Goal 5 — CLI-API Parity

## Goal

Verify CLI behavior parity across success and error paths for the same input set:
- success path exit code and output presence
- error path non-zero handling
- stable interpretation of bundle frontmatter content in CLI output artifacts

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/cli-valid.stdout`, `.exit` — CLI output for test-context.md
- `results/tc/05/cli-valid-cache.stdout`, `.exit` — CLI output for test-context.md with `--output cache`
- `results/tc/05/comparison.md` — success-path comparison summary
- `results/tc/05/cli-error.stdout`, `.stderr`, `.exit` — CLI output for nonexistent file

## Constraints

- Use `ace-bundle` CLI only; do not call internal Ruby APIs.
- Run success path twice:
  - `ace-bundle test-context.md --output stdio`
  - `ace-bundle test-context.md --output cache`
- In `comparison.md`, classify success-path behavior as:
  - `consistent` when both succeed and expose equivalent content semantics, or
  - `divergent` when behavior differs materially.
- Run error path:
  - `ace-bundle nonexistent-file.md --output stdio`
- Error path must be non-zero with informative output.
- All artifacts must come from real tool execution, not fabricated.
