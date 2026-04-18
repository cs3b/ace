# Goal 4 - ace-test-e2e-suite Command Surface + Practical Flow Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/04/`.
2. Use debug evidence only as fallback.

1. `suite_help.exit` is `0`.
2. `suite_help.stdout` includes `Run E2E test suite across all packages`.
3. `suite_help.stdout` includes `--only-failures` and `--affected`.
4. `suite_flow.exit` is `0` or `1`.
5. `suite_flow.stdout` or `suite_flow.stderr` shows practical completion evidence for
   only-failures control flow (for example: no failed scenarios to rerun, 0 selected scenarios,
   or equivalent no-op completion message).

## Verdict

- **PASS**: Help invocation succeeds and practical suite control-flow invocation executes with expected no-op/no-failure-cache semantics.
- **FAIL**: Missing artifacts, wrong help output, or missing practical flow evidence.
