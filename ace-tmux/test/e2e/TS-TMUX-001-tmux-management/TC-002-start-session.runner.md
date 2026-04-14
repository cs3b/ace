# Goal 2 — Start Session

## Goal

Start a session with `ace-tmux start <preset> --detach --name <session-name>`
using the preset recorded by Goal 1 (`selected-preset.txt` when available).
Derive `<session-name>` from the sandbox root so it is unique per run and write
it to `results/tc/02/session-name.txt`.

## Workspace

Save artifacts to `results/tc/02/`.

## Constraints

- If Goal 1 produced `no-preset.txt`, do not fabricate a preset; capture a
  constrained execution note and preserve command evidence for that path.
- Capture command stdout/stderr/exit and the explicit chosen session name:
  - `session-name.txt`
- If start fails, capture a short root-cause note (`start-failure.md`) tied to
  recorded stdout/stderr/exit evidence.
