# Goal 5 — Rewrite Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Dry-run artifacts exist** — results/tc/05/ contains dry-run captures and HEAD hash files.
2. **Dry-run succeeds** — Exit code 0 and output indicates dry-run mode.
3. **HEAD unchanged** — before-head.txt and after-head.txt contain the same hash.
4. **Raw values present** — Scan output shows tokens with raw_value field containing actual token values.

## Verdict

- **PASS**: Dry-run completes without modifying history, and scan output includes raw_value fields.
- **FAIL**: History modified during dry-run, or raw_value missing from scan output.

Report: `PASS` or `FAIL` with evidence.
