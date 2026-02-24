# Goal 5 — Error Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All four capture sets exist** — results/tc/05/ contains captures for circular, missing-ref, nonexistent, and invalid-model.
2. **All non-zero exit codes** — Every error case returns a non-zero exit code.
3. **Informative messages** — Each stderr or stdout contains a relevant error message (circular dependency, not found, invalid model, etc.).
4. **No stack traces** — No Ruby stack traces in any output.

## Verdict

- **PASS**: All 4 error cases return non-zero exits with informative messages and no stack traces.
- **FAIL**: Any error case exits 0, produces unhelpful errors, or shows stack traces.

Report: `PASS` or `FAIL` with evidence (exit codes, error message snippets).
