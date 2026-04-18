# Goal 2 — Start Session Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains start command captures plus explicit session-name
   evidence.
2. Exit code outcome is recorded.
3. `session-name.txt` contains exactly one run-scoped name and that same value is
   referenced in Goal 2 command artifacts (stdout and/or command note).
4. Evidence shows one explicit branch:
   - session created successfully and surfaced by `ace-tmux` output using the
     exact run-scoped name from `session-name.txt`, or
   - constrained execution with explicit reason (`no preset`, `tmux unavailable`,
     or comparable environment limitation) backed by captured artifacts.
5. Failure-path branch includes either `start-failure.md` or explicit start
   stderr evidence when the start command exits non-zero.

## Verdict

- **PASS**: Session start behavior is evidenced through `ace-tmux` output or explicit constraint.
- **FAIL**: Missing run-scoped continuity evidence, missing start evidence, or ambiguous branch outcome.
