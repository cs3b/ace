# Goal 3 — History Persistence Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — results/tc/03/ contains captures for removal and rescan, including removal SHA/show artifacts.
2. **Removal committed** — The removal command exits 0, the captured SHA is non-empty, and `removal.show` proves the committed deletion.
3. **Secrets still detected** — Rescan exit code is non-zero (secrets still in history).

## Verdict

- **PASS**: After git rm + commit, scanner still finds secrets in history.
- **FAIL**: Scanner reports clean after removal, or captures missing.

Report: `PASS` or `FAIL` with evidence (exit codes, detection output after removal).
