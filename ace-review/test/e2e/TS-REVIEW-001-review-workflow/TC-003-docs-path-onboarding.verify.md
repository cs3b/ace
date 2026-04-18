# Goal 3 — Docs Path Onboarding Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Docs/help evidence exists** — `results/tc/03/help.stdout` captures runtime help execution. Use `help.stderr` and `help.exit` as supporting evidence when present.
2. **Docs-path execution succeeded** — `results/tc/03/docs-path.exit` is `0`.
3. **Meaningful review output exists** — docs-path run output/session artifacts show substantive review output.
4. **Session output exists** — `results/tc/03/session-listing.txt` shows created session files.
5. **Failure evidence is actionable when not successful** — if execution fails, stderr clearly identifies a prerequisite/provider issue.
6. **Timeout-constrained path is acceptable** — if `results/tc/03/docs-path.exit` is `124`, treat the goal as pass when:
   - help/onboarding evidence exists
   - `results/tc/03/session-listing.txt` exists and shows prior or current review session artifacts
   - the run does not claim a misleading success
   This records that the docs path was discoverable even though the live review did not finish within the bounded E2E window.

## Verdict

- **PASS**: Docs/help-guided execution succeeds with meaningful review output and session artifacts, or the bounded timeout path still shows discoverable onboarding and session creation evidence.
- **FAIL**: Execution is non-zero without actionable or bounded-timeout evidence, output is ambiguous/non-meaningful, or session artifacts are missing.

Report: `PASS` or `FAIL` with evidence.
