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
2. **Both execution outcomes are explicit** — each run is either:
   - successful (`*.exit` is `0` with generated outputs), or
   - an explicit model-availability blocker with actionable stderr (for example: no model for `review-default`).
3. **Session outputs exist** — Session listing files show session artifacts for both runs.
4. **Evidence is actionable** — artifacts clearly show either successful review generation or explicit environment limitation.

## Verdict

- **PASS**: Multi-model and reviewer-format runs produce either successful output artifacts or explicit model-availability blocker evidence.
- **FAIL**: Either run has ambiguous/missing evidence or fails without actionable diagnostics.

Report: `PASS` or `FAIL` with evidence.
