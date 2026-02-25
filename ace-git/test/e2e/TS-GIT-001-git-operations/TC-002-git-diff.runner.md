# Goal 2 — Git Diff

## Goal

Create a known file change, run `ace-git diff`, and capture output showing the
change appears in diff formatting.

## Workspace

Save artifacts to `results/tc/02/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Ensure there is an unstaged working-tree change immediately before running `ace-git diff` (for example append a new line to an existing tracked file and do not commit it).
- Capture the file mutation command output as `results/tc/02/setup.*` before collecting `ace-git diff` captures.
