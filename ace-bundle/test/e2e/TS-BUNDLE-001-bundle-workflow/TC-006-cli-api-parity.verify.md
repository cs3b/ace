# Goal 6 — CLI-API Parity Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/06/ contains stdout/exit for CLI, API, and error tests.
2. **Valid input: both exit 0** — Both CLI and API exit code is 0 for valid input.
3. **Output match** — The comparison file or direct inspection shows CLI and API outputs are identical (or functionally equivalent).
4. **Error handling: both non-zero** — Both CLI and API return non-zero exit code for nonexistent file input.

## Verdict

- **PASS**: CLI and API produce identical output for valid input and both handle errors consistently.
- **FAIL**: Outputs differ, or error handling is inconsistent.

Report: `PASS` or `FAIL` with evidence (exit codes, output match status, error behavior).
