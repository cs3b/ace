# Goal 6 — CLI-API Parity Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/06/ contains stdout/exit for CLI, API, and error tests.
2. **Valid input: both exit 0** — Both CLI and API exit code is 0 for valid input.
3. **Output equivalence** — The comparison file or direct inspection shows outputs are either:
   - identical, or
   - functionally equivalent by design (CLI may preserve frontmatter while API renders equivalent bundle sections/content).
4. **Error handling: both non-zero** — Both CLI and API return non-zero exit code for nonexistent file input.

## Verdict

- **PASS**: Exit codes and error handling are consistent, and output is identical or explicitly functionally equivalent by design.
- **FAIL**: Exit/error behavior diverges, or output is neither identical nor semantically equivalent.

Report: `PASS` or `FAIL` with evidence (exit codes, output match status, error behavior).
