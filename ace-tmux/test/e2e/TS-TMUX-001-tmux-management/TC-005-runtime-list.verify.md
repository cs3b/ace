# Goal 5 — Runtime List Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/05/` contains captures for the runtime list commands plus an
   exit-code artifact per executed command.
2. Evidence names the intended target session through `target-session.txt` when
   session-scoped list commands were executed.
3. Evidence shows one explicit branch:
   - runtime list commands executed against the concrete run-scoped session, or
   - constrained execution with explicit reason in `list-skip.md`.
4. Runtime list evidence demonstrates the new surface rather than preset
   discovery, including at least one of:
   - pane rows from `ace-tmux list`
   - pane rows from `ace-tmux list --all-panes`
   - window rows from `ace-tmux list --windows`
   - session rows from `ace-tmux list --sessions`

## Verdict

- **PASS**: Runtime list behavior is evidenced through `ace-tmux list` command artifacts or explicit constrained-execution evidence.
- **FAIL**: Missing runtime list artifacts, missing target-session evidence, or ambiguous branch outcome.
