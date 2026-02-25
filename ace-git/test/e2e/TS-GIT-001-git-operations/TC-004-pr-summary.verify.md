# Goal 4 — PR Summary Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/04/` contains PR-context command captures.
2. Command exit code and output are captured.
3. Output includes PR metadata or an explicit no-PR context message.

## Verdict

- **PASS**: PR-related command behaves predictably with evidence.
- **FAIL**: Missing captures or ambiguous behavior.
