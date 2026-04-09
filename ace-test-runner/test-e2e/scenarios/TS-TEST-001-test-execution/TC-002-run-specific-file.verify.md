# Goal 2 — Run Specific File Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains command captures.
2. Exit code is `0`.
3. `results/tc/02/command.txt` references `test/atoms/tool_checker_test.rb`.
4. `results/tc/02/report-files.txt` confirms report material was generated under `results/tc/02/reports`.

## Verdict

- **PASS**: File-scoped execution behaves as expected.
- **FAIL**: Scope evidence missing or command failed.
