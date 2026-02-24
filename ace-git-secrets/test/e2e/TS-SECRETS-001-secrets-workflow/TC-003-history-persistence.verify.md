# Goal 3 — History Persistence Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Both capture sets exist** — results/tc/03/ contains captures for removal and rescan.
2. **Removal committed** — The removal output shows the file was removed and committed.
3. **Secrets still detected** — Rescan exit code is non-zero (secrets still in history).

## Verdict

- **PASS**: After git rm + commit, scanner still finds secrets in history.
- **FAIL**: Scanner reports clean after removal, or captures missing.

Report: `PASS` or `FAIL` with evidence (exit codes, detection output after removal).
