# Goal 3 — Add Window

## Goal

Run `ace-tmux window <preset> --session <session>` against the session created in
Goal 2 and capture evidence that the window add path executed.

If Goal 2 did not produce a usable session/preset, capture an explicit
constrained-execution note instead of fabricating inputs.

## Workspace

Save artifacts to `results/tc/03/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Capture command stdout/stderr/exit and a post-command `tmux ls` snapshot.
- Capture either:
  - successful window-add evidence tied to the target session, or
  - explicit constrained execution note (`window-skip.md`) with reason.
