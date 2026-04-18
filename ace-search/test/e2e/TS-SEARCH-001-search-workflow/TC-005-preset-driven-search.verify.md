# Goal 5 -- Preset-Driven Search Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
   Accept equivalent runner captures under `ace-search/results/tc/{NN}/` when the
   package suite mirrors artifacts there.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `results/tc/05/` or `ace-search/results/tc/05/` contains preset command captures.
2. Exit code is captured.
3. Evidence demonstrates one of the documented user-facing outcomes:
   - preset search executes and returns search output, or
   - command returns an explicit preset configuration error with actionable message.
4. Evidence cites `preset-search.stdout`/`preset-search.stderr` and `preset-search.exit`.

## Verdict

- **PASS**: Preset entrypoint produces clear user-facing behavior with explicit evidence.
- **FAIL**: No preset outcome evidence is captured.
