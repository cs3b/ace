# Goal 5 — Runtime List

## Goal

Run the new live-runtime listing surface against the exact session created in
Goal 2 (`results/tc/02/session-name.txt`) and capture user-facing output for:

- `ace-tmux list --session <session-name>`
- `ace-tmux list --session <session-name> --all-panes`
- `ace-tmux list --session <session-name> --windows`
- `ace-tmux list --sessions`

If Goal 2 did not produce a usable session name, record an explicit
constrained-execution note instead of fabricating inputs.

## Workspace

Save artifacts to `results/tc/05/`.

## Constraints

- Use only declared scenario tools.
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/05/`.
- Copy the exact Goal 2 session name into `results/tc/05/target-session.txt`
  before running session-scoped list commands.
- Capture stdout, stderr, and exit code for each list command as raw artifacts.
- If Goal 2 did not produce a usable session, write `list-skip.md` with the
  explicit reason and do not fabricate a session name.
