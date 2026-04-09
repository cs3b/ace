# Goal 2 — Preset Loading Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — results/tc/02/ contains stdout/exit for both section and simple presets.
2. **Both exit codes zero** — Both presets loaded successfully.
3. **Section preset content** — The section preset stdout contains file content (e.g., "Test Application" from README), command output, and XML-style tags (`<file` or `<output`).
4. **Simple preset content** — The simple preset stdout contains command output (e.g., "Security audit complete").

## Verdict

- **PASS**: Both presets load successfully with expected content in output.
- **FAIL**: Either preset fails, or output lacks expected content.

Report: `PASS` or `FAIL` with evidence (exit codes, content snippets).
