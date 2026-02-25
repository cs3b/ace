# Goal 1 — List Presets Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains list command captures.
2. Exit code is captured.
3. Output includes at least one session preset or explicit empty-state message.
4. Artifact includes selected preset name (if available) for Goal 2.

## Verdict

- **PASS**: Preset discovery behavior is clearly captured.
- **FAIL**: Missing captures or no usable discovery evidence.
