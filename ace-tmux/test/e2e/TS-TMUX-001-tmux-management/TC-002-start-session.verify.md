# Goal 2 — Start Session Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains start command and `tmux ls` captures.
2. Exit code outcome is recorded.
3. Evidence shows session created successfully, or explicit environment/preset
   limitation explaining failure.

## Verdict

- **PASS**: Session start behavior is evidenced (success or explicit constraint).
- **FAIL**: Missing execution evidence or ambiguous outcome.
