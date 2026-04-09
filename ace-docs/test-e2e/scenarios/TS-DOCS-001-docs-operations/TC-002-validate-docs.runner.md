# Goal 2 — Validate Docs

## Goal

Run `ace-docs validate` against the seeded docs corpus and capture validation
output plus process exit evidence.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/validate.stdout|stderr|exit`

Optional capture:
- `results/tc/02/setup.stdout|stderr|exit`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Reuse the docs seeded in Goal 1; do not run validation against an empty workspace.
- If Goal 1 docs are missing, create the same minimal docs set first and capture that bootstrap as `results/tc/02/setup.*`.
