# Goal 4 - ace-test-e2e-suite Help Command Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/04/`.
2. Use debug evidence only as fallback.

1. `suite_help.exit` is `0`.
2. `suite_help.stdout` includes `Run E2E test suite across all packages`.
3. `suite_help.stdout` includes `--only-failures` and `--affected`.

## Verdict

- **PASS**: Suite help invocation succeeds and shows expected suite-level options.
- **FAIL**: Missing artifacts, wrong exit code, or missing expected help text.
