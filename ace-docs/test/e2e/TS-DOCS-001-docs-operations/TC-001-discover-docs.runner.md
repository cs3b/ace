# Goal 1 — Discover Docs

## Goal

Run `ace-docs discover` against a seeded docs corpus and capture evidence that
the CLI reports managed documents.

## Workspace

Save artifacts to `results/tc/01/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
- Seed a minimal managed docs set before running discover (for example `docs/guide.md` and `docs/reference.md`), each with valid frontmatter including `doc-type` and `last-updated`.
- Capture the create/setup commands in `results/tc/01/setup.stdout|stderr|exit` so later goals can reuse the same docs corpus.
- Capture discover command output as:
  - `results/tc/01/discover.stdout`
  - `results/tc/01/discover.stderr`
  - `results/tc/01/discover.exit`
- Ensure at least two markdown documents are present in `docs/` before running discover.
