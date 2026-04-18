# Goal 6 -- Git-Scoped Search

## Goal

Run `ace-search "ace-search" --tracked .` and capture output showing search
scope constrained to tracked files.

## Workspace

Save artifacts to `results/tc/06/`.

Capture:

- `results/tc/06/tracked-search.stdout`, `.stderr`, `.exit`
- `results/tc/06/summary.md` (optional) with scope and representative evidence

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/06/`.
- Do not write outside the sandbox.
- Validate public git-scope flags from the CLI contract, not hidden internals.
