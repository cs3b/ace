# Goal 5 — Window Outside tmux With Explicit Session

## Goal

Validate the documented outside-tmux path by running:
`ace-tmux window <window-preset> --session <session-name>`.

Use real command evidence only. Do not use direct `tmux` probing.

## Workspace

Save artifacts to `results/tc/05/`.

## Constraints

- Discover presets through `ace-tmux list` commands:
  - choose one session preset and one window preset when available
  - write `selected-session-preset.txt` and `selected-window-preset.txt`
- Create a detached target session with:
  `ace-tmux start <session-preset> --detach --name <session-name>`
  and save `<session-name>` to `target-session.txt`.
- Run `ace-tmux window <window-preset> --session <session-name>` from outside tmux.
- Capture stdout/stderr/exit for list/start/window commands.
- If session/window presets are unavailable, write `outside-window-skip.md` with
  explicit reason and do not fabricate inputs.
- If start or window commands are attempted and exit non-zero, write
  `outside-window-failure.md` with a short root-cause note tied to artifacts.
