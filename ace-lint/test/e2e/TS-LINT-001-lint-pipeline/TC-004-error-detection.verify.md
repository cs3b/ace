# Goal 4 — Error Detection Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — files exist in `results/tc/04/` including exit code and target/context captures.
2. **Negative fixture proven** — the captured target/context artifacts show the run actually targeted the intended failing fixture.
3. **Failure evidence** — at least one of the following is true:
   - lint exit code is non-zero; or
   - stdout/stderr reports lint issues for the targeted file; or
   - a pending report artifact exists for the targeted file.
4. **No false clean result** — if the run reports `All files passed`, the captured target/context evidence must still explain why the negative fixture was not active; otherwise the scenario fails.

## Verdict

- **PASS**: The run clearly targeted the failing fixture and produced issue evidence or a well-explained non-clean outcome.
- **FAIL**: The runner cannot prove it targeted the failing fixture, or it reports a clean run with no issue evidence.

Report: `PASS` or `FAIL` with evidence (target file, exit code, issue snippet).
