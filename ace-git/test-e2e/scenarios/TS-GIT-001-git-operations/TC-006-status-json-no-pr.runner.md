# Goal 6 — Status JSON Without PR Lookups

## Goal

Run `ace-git status --format json --no-pr` and capture deterministic JSON output
without PR/network dependency.

## Workspace

Save artifacts to `results/tc/06/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/06/`.
- Do not write outside the sandbox.
- Capture stdout, stderr, and exit code as `status-json-no-pr.stdout|stderr|exit`.
