# Goal 3 -- Count/List Semantics

## Goal

Run `ace-search --type content --files-with-matches "Goal" .`
and `ace-search --type content --count "ace-search" .`,
then capture user-visible list/count outcomes.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:

- `results/tc/03/files-with-matches.stdout`, `.stderr`, `.exit`
- `results/tc/03/count.stdout`, `.stderr`, `.exit`
- `results/tc/03/summary.md` (optional) with observed count/list semantics

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Treat each command as one clear user outcome: list files with matches, then report numeric counts.
