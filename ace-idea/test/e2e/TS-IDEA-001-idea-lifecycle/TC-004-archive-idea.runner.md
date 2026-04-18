# Goal 4 — Archive Idea

## Goal

Move the idea to archive scope with `ace-idea update {id} --move-to archive`.
Then run `ace-idea list --in archive` to confirm archived ideas are visible
through folder filtering.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/update-archive.stdout`, `.stderr`, `.exit`
- `results/tc/04/list-archive.stdout`, `.stderr`, `.exit`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- Reuse the exact idea ID saved in `results/tc/03/idea-id.txt` (derived from the public create output flow).
- Do not pass filename or path to `ace-idea update`.
