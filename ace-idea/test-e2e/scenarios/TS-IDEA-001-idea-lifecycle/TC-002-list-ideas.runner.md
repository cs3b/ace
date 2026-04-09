# Goal 2 — List Ideas

## Goal

Run `ace-idea list` to confirm the idea created in Goal 1 appears in listing
output. Also run `ace-idea list --status pending` to verify status-based
filtering returns the same idea, and `ace-idea list --in next` to verify
folder filtering includes root-scoped ideas.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/list.stdout`, `.stderr`, `.exit`
- `results/tc/02/list-pending.stdout`, `.stderr`, `.exit`
- `results/tc/02/list-next.stdout`, `.stderr`, `.exit`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
