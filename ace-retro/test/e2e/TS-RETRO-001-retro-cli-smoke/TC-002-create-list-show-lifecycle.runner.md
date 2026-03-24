# Goal 2 - Create/List/Show Lifecycle

## Goal

Create a retro, then verify list/show commands can read the persisted file across
separate CLI invocations.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/create.stdout`, `.stderr`, `.exit` from a create command with tags
- `results/tc/02/retro-id.txt` containing the created retro ID parsed from output
- `results/tc/02/list.stdout`, `.stderr`, `.exit` from `ace-retro list`
- `results/tc/02/show.stdout`, `.stderr`, `.exit` from `ace-retro show <id>`
- `results/tc/02/show-path.stdout`, `.stderr`, `.exit` from `ace-retro show <id> --path`
- `results/tc/02/retro-file.path` containing resolved retro file path
- `results/tc/02/retro-file.md` copied retro file content

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
