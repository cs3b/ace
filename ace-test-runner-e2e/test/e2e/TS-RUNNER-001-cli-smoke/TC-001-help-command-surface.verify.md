# Goal 1 - ace-test-e2e Help Command Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/01/`.
2. Use debug evidence only as fallback.

1. `help.exit` is `0`.
2. `help.stdout` includes `Run E2E tests via LLM execution`.
3. `help.stdout` includes `--dry-run` and `--provider`.

## Verdict

- **PASS**: Help invocation succeeds and exposes expected options/description.
- **FAIL**: Missing artifacts, wrong exit code, or missing expected help text.
