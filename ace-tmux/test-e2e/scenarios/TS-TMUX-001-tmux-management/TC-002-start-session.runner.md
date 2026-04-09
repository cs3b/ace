# Goal 2 — Start Session

## Goal

Start a session with `ace-tmux start <preset> --detach` using the preset
recorded by Goal 1 (`selected-preset.txt` when available), then verify
session presence with `tmux ls`.

## Workspace

Save artifacts to `results/tc/02/`.

## Constraints

- If Goal 1 produced `no-preset.txt`, do not fabricate a preset; capture a
  constrained execution note and preserve command evidence for that path.
- Capture command stdout/stderr/exit and `tmux ls` output as explicit artifacts.
- If start fails, capture a short root-cause note (`start-failure.md`) tied to
  recorded stdout/stderr/exit evidence.
