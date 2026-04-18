# Goal 5 — Window Outside tmux With Explicit Session Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/05/` includes list/start/window command captures with exit codes.
2. Evidence shows one explicit branch:
   - successful path with `target-session.txt`, `window.exit` equal to `0`, and
     `ace-tmux window` stdout evidence, or
   - explicit constrained execution in `outside-window-skip.md` (`no session preset`,
     `no window preset`, `tmux unavailable`, or comparable environment limitation), or
   - attempted outside-tmux path with explicit `outside-window-failure.md` that
     cites start/window artifacts and a concrete limitation (for example session
     lookup failure).
3. If start/window commands were attempted and exited non-zero,
   `outside-window-failure.md` exists and cites the related artifacts.

## Verdict

- **PASS**: Outside-tmux window targeting is evidenced through `ace-tmux` artifacts
  or explicit constrained-execution evidence.
- **FAIL**: Missing command artifacts, missing branch evidence, or ambiguous
  success/constraint/failure classification.
