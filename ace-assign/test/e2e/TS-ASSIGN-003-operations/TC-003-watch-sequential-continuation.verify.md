# Goal 3 — Watch-Driven Sequential Fork Continuation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/03/`.
3. Use debug evidence only as fallback.

1. **Assignment created** — create command succeeded and assignment ID exists.
2. **Watch invoked** — watch command evidence is present.
3. **Sequential continuation happened** — post-watch evidence shows the fork subtrees are terminal without requiring a second watch invocation artifact.
4. **Legitimate stop boundary** — the returned state is coherent: inline/manual work is next, or the assignment is complete.

## Verdict

- **PASS**: Watch-driven continuation is demonstrated with coherent before/after state.
- **FAIL**: Watch invocation missing, fork children did not advance as expected, or returned state is inconsistent.

Report: `PASS` or `FAIL` with evidence (watch output and before/after status).
