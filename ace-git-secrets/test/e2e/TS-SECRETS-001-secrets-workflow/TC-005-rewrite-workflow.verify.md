# Goal 5 — Rewrite Workflow (Saved Report Contract) Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Saved report artifact exists** — `saved-report.json` is present.
2. **Saved report carries revocation data** — `saved-report.json` contains token entries with `raw_value` fields.
3. **Dry-run succeeds with scan-file** — dry-run exit code is `0` and output indicates dry-run mode.
4. **Dry-run is history-safe** — `before-head.txt` equals `after-head.txt`.

## Verdict

- **PASS**: Saved report contract is valid and dry-run rewrite completes without history mutation.
- **FAIL**: Missing `raw_value`, dry-run failure, or HEAD change during dry-run.

Report: `PASS` or `FAIL` with evidence.
