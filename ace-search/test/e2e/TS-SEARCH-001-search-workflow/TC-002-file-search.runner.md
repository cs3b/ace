# Goal 2 -- File Search

## Goal

Run `ace-search --files "*.md" .` and capture file-list output proving a
user can discover markdown files from the current workspace without hidden,
repository-internal paths.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:

- `results/tc/02/file-search.stdout`, `.stderr`, `.exit`
- `results/tc/02/summary.md` (optional) with command scope and representative paths

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Use a public workspace-relative path (`.`) so the journey is reproducible from docs/help usage patterns.
