# Goal 6 — Single Model Execution Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — results/tc/06/ contains execution captures and session listing.
2. **Zero exit code** — Review execution succeeded.
3. **Session directory created** — Session listing shows a directory was created with review output.
4. **Prepared execution evidence** — Execution output shows either:
   - a real review output file with substantive content, or
   - a prepared review session with prompt files and an explicit `To execute with LLM:` handoff command.
5. **Support capture optional** — `review-output.md` may be present as support evidence, but its absence alone is not a failure when execution output and session listing already prove the run.

## Verdict

- **PASS**: Review execution or session preparation succeeded and created a usable review session.
- **FAIL**: Execution failed, no session was created, or no usable execution/preparation evidence exists.

Report: `PASS` or `FAIL` with evidence (exit code, session directory, content snippet).
