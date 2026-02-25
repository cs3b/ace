# Goal 5 — Output Override Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — results/tc/05/ contains stdout/exit for both override tests.
2. **Both exit codes zero** — Both invocations succeeded.
3. **Large forced to stdio** — The large-to-stdio stdout contains actual content (e.g., "Large Test Content") and does NOT contain "Bundle saved".
4. **Small forced to cache** — The small-to-cache stdout contains "Bundle saved" or "output file:" cache reference.

## Verdict

- **PASS**: --output stdio forces inline output for large content, --output cache forces cache file for small content.
- **FAIL**: Override does not work, or captures missing.

Report: `PASS` or `FAIL` with evidence (content snippets, cache indicators).
