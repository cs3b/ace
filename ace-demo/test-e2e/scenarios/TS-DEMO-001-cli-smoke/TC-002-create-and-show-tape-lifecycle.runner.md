# Goal 2 - Create and Show Tape Lifecycle

## Goal

Validate real CLI lifecycle for tape creation and inspection across commands.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/create.stdout`, `.stderr`, `.exit` from:
  `ace-demo create my-demo -- "echo hello"`
- `results/tc/02/show.stdout`, `.stderr`, `.exit` from:
  `ace-demo show my-demo`
- `results/tc/02/tape-ls.stdout`, `.stderr`, `.exit` from:
  `ls -la .ace/demo/tapes`

## Constraints

- Preserve command order: create first, then show.
- Capture evidence only; do not produce verdicts.
- Keep artifacts under `results/tc/02/`.
