# Goal 3 — Add Window

## Goal

Run `ace-tmux window <preset> --session <session>` against the exact session
created in Goal 2 (`results/tc/02/session-name.txt`) and capture the user-facing
result from `ace-tmux`.

Select `<preset>` from `ace-tmux list windows` output (write
`selected-window-preset.txt`), not from Goal 1 session-preset artifacts.

If Goal 2 did not produce a usable session/preset, capture an explicit
constrained-execution note instead of fabricating inputs.

## Workspace

Save artifacts to `results/tc/03/`.

## Constraints

- Use only declared scenario tools.
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Copy the exact Goal 2 session name into `results/tc/03/target-session.txt`
  before running the window command so Goal 3 evidence names the concrete target
  session directly.
- Capture command stdout/stderr/exit only. Do not add direct `tmux` probing or
  cleanup commands to prove internal state that `ace-tmux` does not expose.
- If no window preset is available from `ace-tmux list windows`, write
  `window-skip.md` with an explicit reason and do not fabricate a preset.
- Do not use `results/tc/01/selected-preset.txt` as a window preset input.
- Capture either:
  - successful `ace-tmux window` evidence tied to the target session, or
  - explicit constrained execution note (`window-skip.md`) with reason.
