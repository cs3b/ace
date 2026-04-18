# Goal 3 - Public Shell Helper Coverage Verification

## Expectations

1. `sh_ls.exit` is `0`.
2. `sh_ls.stdout` lists files/directories from `.ace-local/test-e2e/runner-002-report`.
3. `sh_ls.stderr` contains no path-safety failure for this valid path.

## Verdict

- **PASS**: `ace-test-e2e-sh` works on the generated sandbox report path.
- **FAIL**: Wrong exit code, missing listing, or path validation failure.
