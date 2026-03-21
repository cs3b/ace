# Goal 2 — File Search

## Goal

Run `ace-search --files "*.rb" "$PROJECT_ROOT_PATH/ace-search"` and capture
file-list output showing glob-based file discovery against a deterministic
project path.

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
- Use the explicit package path rooted at `$PROJECT_ROOT_PATH` so `.rb` files are
  guaranteed to exist regardless of sandbox contents.
