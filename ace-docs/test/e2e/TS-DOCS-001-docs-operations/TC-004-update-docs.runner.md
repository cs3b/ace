# Goal 4 - Update Docs

## Goal

Run `ace-docs update` on one seeded document and capture evidence that frontmatter
metadata was updated through the CLI.

## Workspace

Save artifacts to `results/tc/04/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- Reuse the docs corpus from prior goals; if missing, recreate and capture bootstrap as `results/tc/04/setup.*`.
- Capture pre-update file content snapshot as `results/tc/04/before.md`.
- Capture update command artifacts as:
  - `results/tc/04/update.stdout`
  - `results/tc/04/update.stderr`
  - `results/tc/04/update.exit`
- Capture post-update file content snapshot as `results/tc/04/after.md`.
