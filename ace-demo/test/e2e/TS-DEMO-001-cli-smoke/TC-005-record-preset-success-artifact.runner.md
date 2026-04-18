# Goal 5 - Record Preset Success Artifact

## Goal

Validate the non-dry-run recording path for a documented preset (`hello`) and
capture concrete output artifact evidence.

## Workspace

Save artifacts to `results/tc/05/`.

Capture:
- `results/tc/05/record-success.stdout`, `.stderr`, `.exit` from:
  `ace-demo record hello --output results/tc/05/hello.gif`
- `results/tc/05/artifact-ls.stdout`, `.stderr`, `.exit` from:
  `ls -la results/tc/05`

## Constraints

- Run non-dry-run mode for this goal.
- Capture evidence only; do not produce verdicts.
- Keep artifacts under `results/tc/05/`.
