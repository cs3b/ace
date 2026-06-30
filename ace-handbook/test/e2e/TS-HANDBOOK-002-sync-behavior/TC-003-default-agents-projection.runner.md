# Goal 3 - Default agents projection includes legacy workflow skills

## Goal

Run the default sync and capture evidence that the neutral `agents` provider receives common workflow skills from the
legacy full-provider target set.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:

- `results/tc/03/sync-agents.stdout`, `.stderr`, `.exit` from `ace-handbook sync`
- `results/tc/03/status-agents.stdout`, `.stderr`, `.exit` from `ace-handbook status`

## Constraints

- Use only declared scenario tools.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
