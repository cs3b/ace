# Goal 3 — Decode Token Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Command captures exist** — `decode.stdout`, `decode.stderr`, and `decode.exit` exist in `results/tc/03/`.
2. **Decode succeeded** — `decode.exit` indicates success.
3. **Stdout contains a decoded timestamp** — `decode.stdout` is non-empty and contains a recognizable date or timestamp.
4. **Decoded value is plausible** — The decoded date is a real, reasonable date, not blank or obviously invalid.

## Verdict

- **PASS**: The decode command succeeds and stdout contains a valid, plausible decoded date or timestamp.
- **FAIL**: Captures are missing, the command fails, or stdout does not contain a recognizable decoded value.

Report: `PASS` or `FAIL` with evidence from `decode.stdout`, `decode.stderr`, and `decode.exit`.
