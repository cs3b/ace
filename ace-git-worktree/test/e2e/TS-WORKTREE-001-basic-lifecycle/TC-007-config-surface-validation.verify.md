# Goal 7 — Config Surface Validation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/07/ contains stdout/exit for config-show, config-validate, and config-files.
2. **Show output is usable** — config-show.exit is 0 and config-show.stdout is non-empty.
3. **Validate command succeeds** — config-validate.exit is 0 and output indicates valid configuration.
4. **Config file locations are visible** — config-files.exit is 0 and config-files.stdout lists at least one config path/source.

## Verdict

- **PASS**: Users can inspect config, validate config, and inspect active config file sources from CLI output.
- **FAIL**: Required artifacts are missing, commands fail, or output is empty/non-actionable.

Report: `PASS` or `FAIL` with evidence (exit codes and key output lines).
