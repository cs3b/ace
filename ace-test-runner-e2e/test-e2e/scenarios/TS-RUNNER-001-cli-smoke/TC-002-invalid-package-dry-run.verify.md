# Goal 2 - Invalid Package Dry-Run Error Path Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/02/`.
2. Use debug evidence only as fallback.

1. `invalid_pkg.exit` is non-zero.
2. `invalid_pkg.stderr` includes `No tests found for package 'not-a-real-package'`.
3. No unexpected scenario preview lines appear in `invalid_pkg.stdout`.

## Verdict

- **PASS**: CLI reports a deterministic package-not-found dry-run error with non-zero exit.
- **FAIL**: Missing artifacts, success exit, or missing expected error text.
