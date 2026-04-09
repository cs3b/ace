# Goal 1 - Help and Command Surface Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/01/`.
2. Use debug evidence only as fallback.

1. `help.exit` is `0`.
2. `help.stdout` includes `list`, `show`, `record`, `retime`, `attach`, and `create`.

## Verdict

- **PASS**: Help invocation succeeds and exposes expected command surface.
- **FAIL**: Missing artifacts, wrong exit code, or missing command names.
