# Goal 4 - Doctor Health/Error Path Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm broken task file exists in sandbox state.
2. Confirm healthy/broken doctor runs were captured.
3. Use stderr/exit fallback only when needed.

1. `doctor-healthy.exit` is `0`.
2. `doctor-broken.exit` is non-zero.
3. `broken-task.txt` exists and includes invalid frontmatter content.

## Verdict

- **PASS**: Doctor passes on healthy state and fails after malformed task injection.
- **FAIL**: Expected healthy/broken split is not observed.
