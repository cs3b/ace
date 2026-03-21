# Goal 4 - Attach PR Validation Error

## Goal

Validate operator-visible CLI validation behavior when required `--pr` is missing.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/attach-missing-pr.stdout`, `.stderr`, `.exit` from:
  `ace-demo attach .ace-local/demo/example.gif`

## Constraints

- Capture evidence only; do not produce verdicts.
- Keep artifacts under `results/tc/04/`.
