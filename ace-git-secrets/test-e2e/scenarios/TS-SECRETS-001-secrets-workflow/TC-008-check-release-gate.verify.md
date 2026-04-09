# Goal 8 - Check-Release Gate Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** - `results/tc/08/` contains JSON and strict-mode command captures.
2. **Release gate fails with findings** - both `.exit` files are non-zero.
3. **JSON shape present** - JSON command output includes `passed`, `message`, `token_count`, and `tokens`.
4. **Strict-mode messaging present** - strict command output includes pre-release check messaging.

## Verdict

- **PASS**: Both command variants run, fail appropriately on detected token history, and JSON output shape is valid.
- **FAIL**: Missing artifacts, zero exit, or missing expected JSON/message fields.

Report: `PASS` or `FAIL` with evidence (exit codes, JSON keys, message snippets).
