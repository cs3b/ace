# Goal 3 — Add Window Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` contains window command captures and an exit code artifact.
2. Evidence names the intended target session through `target-session.txt` and
   includes successful `ace-tmux window` command artifacts for that run.
3. Evidence shows one explicit branch:
   - `ace-tmux window` executed for the concrete targeted run-scoped session, or
   - constrained execution with explicit reason in `window-skip.md` because no
     window preset is available or an upstream Goal 2 prerequisite failed.
4. If a window command was attempted and exited non-zero, `window-failure.md`
   exists and cites the captured command artifacts.

## Verdict

- **PASS**: Window behavior is evidenced through `ace-tmux` command artifacts or explicit constrained-execution evidence.
- **FAIL**: Missing command artifacts, missing target-session continuity
  artifacts, or ambiguous constrained/failure branch evidence.
