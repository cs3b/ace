# Goal 2 — Start Session Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains start command and `tmux ls` captures.
2. Exit code outcome is recorded.
3. Evidence shows one explicit branch:
   - session created successfully and listed in `tmux ls`, or
   - constrained execution with explicit reason (`no preset`, `tmux unavailable`,
     or comparable environment limitation) backed by captured artifacts.
4. Failure-path branch includes `start-failure.md` when the start command exits
   non-zero.

## Verdict

- **PASS**: Session start behavior is evidenced (success or explicit constraint).
- **FAIL**: Missing start evidence, missing `tmux ls` evidence, or ambiguous branch outcome.
