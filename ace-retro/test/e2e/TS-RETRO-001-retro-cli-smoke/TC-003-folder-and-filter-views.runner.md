# Goal 3 - Folder and Filter Views

## Goal

Validate special-folder placement and list filtering using real on-disk retros.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/create-archive.stdout`, `.stderr`, `.exit` from create with `--move-to archive`
- `results/tc/03/list-archive.stdout`, `.stderr`, `.exit` from `ace-retro list --in archive`
- `results/tc/03/list-status.stdout`, `.stderr`, `.exit` from `ace-retro list --status active`
- `results/tc/03/list-tags.stdout`, `.stderr`, `.exit` from `ace-retro list --tags sprint`
- `results/tc/03/archive-tree.txt` with a compact listing of `.ace-retros` subtree

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
