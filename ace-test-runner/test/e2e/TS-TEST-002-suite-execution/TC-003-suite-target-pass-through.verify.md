# Goal 3 — Suite Target Pass-Through Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` contains command captures.
2. `results/tc/03/command.txt` confirms `ace-test-suite --config .ace/test/suite.yml --target fast`.
3. `results/tc/03/command.exit` exists and contains a numeric exit code.
4. Output captures provide suite execution evidence consistent with a targeted run.

## Verdict

- **PASS**: Suite target option is passed through and produces coherent execution evidence.
- **FAIL**: Command capture is missing the `--target` contract or execution evidence is incomplete.
