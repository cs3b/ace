# Goal 1 — Run Package Tests Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Artifacts exist in `results/tc/01/`.
2. `results/tc/01/command.txt` records `ace-test "$PROJECT_ROOT_PATH/ace-search" atoms`.
3. `results/tc/01/report-files.txt` confirms report output under `results/tc/01/reports`.
4. Exit code is `0`.
5. Captured output includes executed test summary details.

## Verdict

- **PASS**: Package test run succeeds with real execution evidence.
- **FAIL**: Missing artifacts or non-zero execution result.
