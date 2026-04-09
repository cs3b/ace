# Goal 1 - Help and Usage Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/01/`.
2. Use debug evidence only as fallback.

1. `help.exit` is `0`.
2. `help.stdout` includes command usage/help content for `ace-retro`.
3. `create-missing-title.exit` is non-zero (`1` expected).
4. `create-missing-title.stderr` includes `Title required`.

## Verdict

- **PASS**: Help invocation succeeds and missing-title command fails with expected message.
- **FAIL**: Missing artifacts, wrong exit codes, or missing error text.
