# Goal 3 — History Persistence Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Removal capture exists** — `results/tc/03/removal.stdout` and `results/tc/03/removal.exit` are present.
2. **Removal committed** — The removal output shows the file was removed and committed.
3. **Secrets still detected** — `results/tc/03/rescan.stdout`, `results/tc/03/rescan.stderr`, and `results/tc/03/rescan.exit` prove the post-removal scan still reports token findings from git history.

## Verdict

- **PASS**: After git rm + commit, the TC-003 rescan still finds secrets in history.
- **FAIL**: Scanner reports clean after removal, removal evidence is missing, or the TC-003 rescan artifacts are incomplete.

Report: `PASS` or `FAIL` with evidence (exit codes, detection output after removal).
