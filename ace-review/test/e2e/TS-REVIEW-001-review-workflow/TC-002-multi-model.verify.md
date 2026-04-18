# Goal 2 — Multi-Model and Reviewers Format Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Both capture sets exist** — `results/tc/02/` contains artifacts for `multi` and `reviewers` runs.
2. **Both executions succeeded** — `multi.exit` and `reviewers.exit` are both `0`.
3. **Both runs produced meaningful review output** — each run either emits substantive review text directly or
   shows a saved review report path plus session artifacts proving a review report file was created.
4. **Session outputs exist** — Session listing files show session artifacts for both runs.
5. **Failure evidence is actionable when not successful** — if either run fails, stderr clearly identifies a prerequisite/provider issue.

## Verdict

- **PASS**: Multi-model and reviewer-format runs both succeed with meaningful output artifacts.
- **FAIL**: Either run is non-zero (including provider/model unavailability), has ambiguous/non-meaningful output, is missing session artifacts, or lacks actionable failure diagnostics.

Report: `PASS` or `FAIL` with evidence.
