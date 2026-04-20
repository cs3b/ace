# Goal 3 — History Persistence Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Removal capture exists** — results/tc/03/ contains removal evidence.
2. **Removal committed** — The removal output shows the file was removed and committed.
3. **Secrets still detected** — Prefer `results/tc/03/rescan.*`; if that capture is missing, accept a later real scan artifact from this same scenario, such as `results/tc/04/json-scan.*`, `results/tc/04/whitelist-scan.*`, or `results/tc/07/defaults.*`, when it runs after the committed removal and still reports token findings.

## Verdict

- **PASS**: After git rm + commit, scanner still finds secrets in history, proven by TC-003 rescan or a later real scan artifact in the same scenario.
- **FAIL**: Scanner reports clean after removal, removal evidence is missing, or no post-removal scan evidence exists.

Report: `PASS` or `FAIL` with evidence (exit codes, detection output after removal).
