# Goal 4 — Existing Session Start Behavior

## Goal

Exercise `ace-tmux start` behavior when a target session already exists:

1. Start (or reuse) a detached session using the preset selected in Goal 1.
2. Re-run `ace-tmux start <preset> --detach --name <same-session>` (without
   `--force`) and capture reuse-path output.
3. Run `ace-tmux start <preset> --detach --name <same-session> --force` and
   capture force-recreate output.

Use the Goal 2 `session-name.txt` when available. If absent, derive one from the
sandbox root and save it to `results/tc/04/session-name.txt`.

## Workspace

Save artifacts to `results/tc/04/`.

## Constraints

- If Goal 1 produced `no-preset.txt`, do not fabricate a preset; write
  `existing-session-skip.md` with explicit reason.
- Capture stdout/stderr/exit for each command attempt:
  - `initial-start.*`
  - `reuse-start.*`
  - `force-start.*`
- Keep all artifacts under `results/tc/04/`.
- If any attempted command exits non-zero, write `existing-session-failure.md`
  with a short root-cause note tied to captured artifacts.
