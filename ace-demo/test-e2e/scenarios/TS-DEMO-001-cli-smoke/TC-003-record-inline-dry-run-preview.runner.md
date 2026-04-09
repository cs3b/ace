# Goal 3 - Record Inline Dry-Run Preview

## Goal

Validate inline recording dry-run behavior (content preview and attach preview)
without external side effects.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/record-dry-run.stdout`, `.stderr`, `.exit` from:
  `ace-demo record smoke-demo --dry-run --pr 123 -- "echo hello"`

## Constraints

- Use dry-run mode only; do not perform real upload actions.
- Capture evidence only; do not produce verdicts.
- Keep artifacts under `results/tc/03/`.
