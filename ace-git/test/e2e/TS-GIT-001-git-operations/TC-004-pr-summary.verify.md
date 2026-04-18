# Goal 4 -- PR Summary Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/04/` contains PR-context command captures.
2. `pr.exit` and corresponding `pr.stdout|stderr` are present.
3. PASS path A: `pr.exit == 0` and output includes PR metadata fields.
4. PASS path B: `pr.exit != 0` and `pr.stderr` or `pr.stdout` contains explicit
   no-PR context evidence (for example: no pull request found for branch, or
   PR number required/unknown in current context).

## Verdict

- **PASS**: PR command succeeds with metadata OR fails with explicit no-PR evidence.
- **FAIL**: Missing captures, ambiguous no-PR evidence, or unexpected failure mode.
