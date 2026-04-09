# Goal 3 — Status Check

## Goal

Run `ace-docs status` and capture documentation health/coverage summary output
for the same docs corpus used by prior goals.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/status.stdout|stderr|exit`

Optional capture:
- `results/tc/03/setup.stdout|stderr|exit`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Reuse the docs corpus from Goals 1-2 so status output has real managed documents to summarize.
- If the docs corpus is missing, create it before status and capture the bootstrap in `results/tc/03/setup.*`.
