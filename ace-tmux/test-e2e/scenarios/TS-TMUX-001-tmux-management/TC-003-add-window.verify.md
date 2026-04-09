# Goal 3 — Add Window Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` contains window command captures and an exit code artifact.
2. Post-command `tmux ls` output is captured.
3. Evidence shows one explicit branch:
   - window add path executed for a concrete session, or
   - constrained execution with explicit reason in `window-skip.md`.

## Verdict

- **PASS**: Window behavior is evidenced through command artifacts or explicit constrained-execution evidence.
- **FAIL**: Missing command artifacts, missing branch evidence, or ambiguous window outcome.
