# Goal 4 - Doctor Health/Error Path Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm the invalid-status task file exists in sandbox state.
2. Confirm healthy/broken doctor runs were captured.
3. Use stderr/exit fallback only when needed.

1. `doctor-healthy.exit` is `0`.
2. `doctor-broken.exit` is `0` or `1`, but the command output must explicitly surface the invalid status issue.
3. `broken-task.txt` exists and includes an invalid `status` value in otherwise valid frontmatter.
4. `doctor-broken.stdout` or `doctor-broken.stderr` mentions the invalid status issue as a warning or error.

## Verdict

- **PASS**: Doctor passes on healthy state and explicitly reports the injected invalid-status issue.
- **FAIL**: The invalid-status issue is not surfaced in doctor output.
