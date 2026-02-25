# Goal 4 — Auto-Format Threshold Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — results/tc/04/ contains stdout/exit for both small and large presets.
2. **Both exit codes zero** — Both presets processed successfully.
3. **Small preset to stdio** — Small stdout contains actual content (e.g., "Small Test Content") and does NOT contain "Bundle saved" or "output file:".
4. **Large preset to cache** — Large stdout contains "Bundle saved" or "output file:" with a cache path, and does NOT contain the full content inline.

## Verdict

- **PASS**: Small content goes to stdio, large content goes to cache file.
- **FAIL**: Routing is wrong for either size, or captures missing.

Report: `PASS` or `FAIL` with evidence (content snippets, presence/absence of cache indicators).
