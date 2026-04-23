# Goal 1 — Saved-Report Remediation Path Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Core artifacts exist** — scan/revoke/rewrite captures exist with exit files and saved-report artifacts.
2. **Saved report comes from the default history scan** — `saved-report.json` does not narrow the scan to `since: HEAD`, and the recorded `commits_scanned` value shows history was actually scanned.
3. **Saved report is usable** — `saved-report.json` includes token entries with `raw_value` fields required by remediation commands.
4. **Revoke step is explicit and safe** — revoke command executes with `--scan-file` and either:
   - performs revocation attempts, or
   - clearly reports a no-op state such as \"No tokens found to revoke\" when no revocable token types are present.
5. **Rewrite dry-run is safe** — rewrite dry-run exits successfully and `before-head.txt` equals `after-head.txt`.

## Verdict

- **PASS**: Public remediation path is reproducible through saved-report contract with explicit revoke behavior and dry-run history safety.
- **FAIL**: Missing contract artifacts, failed remediation commands, or HEAD mutation during dry-run.

Report: `PASS` or `FAIL` with evidence.
