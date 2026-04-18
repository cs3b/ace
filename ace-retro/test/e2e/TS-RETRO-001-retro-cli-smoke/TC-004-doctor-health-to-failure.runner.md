# Goal 4 - Doctor Health to Failure Transition

## Goal

Run `ace-retro doctor` once on valid state, then intentionally corrupt one retro
file and confirm doctor detects failure in a subsequent run.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:

- `results/tc/04/doctor-healthy.stdout`, `.stderr`, `.exit` from initial `ace-retro doctor`
- `results/tc/04/corrupted-file.path` containing path to the file intentionally corrupted
- `results/tc/04/corrupted-file.md` capturing corrupted content snapshot
- `results/tc/04/doctor-broken.stdout`, `.stderr`, `.exit` from doctor after corruption

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Corruption must remain inside sandbox-local retro files only.
- Corruption must produce invalid frontmatter (error-level), not only a scope warning:

  - Pick one `*.retro.md` file under scenario-local `.ace-retros/`.
  - Persist its path in `results/tc/04/corrupted-file.path`.
  - Overwrite that file with clearly malformed YAML frontmatter so a user-observable doctor failure occurs. Use a deterministic syntax break such as an unclosed list/map value or an unterminated quote; do not merely change `status`.
  - Save the resulting file content in `results/tc/04/corrupted-file.md`.

- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
