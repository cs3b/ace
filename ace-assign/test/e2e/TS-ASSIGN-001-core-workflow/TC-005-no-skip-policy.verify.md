# Goal 5 — No-Skip Policy Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **No-skip rule present** — `no-skip-rule.stdout` contains the mandatory no-skip policy text about planned phases being mandatory.
2. **Synthetic skip prohibited** — `synthetic-skip.stdout` contains prohibition against using report text to skip or synthesize completion.
3. **Skip Assessment removed** — `skip-assessment.stdout` confirms no "Skip Assessment" section exists (empty or no match).
4. **Attempt-first section** — `attempt-first.stdout` contains the External Action Rule (Attempt-First) section header.
5. **Evidence requirements** — `evidence-rules.stdout` contains requirements for "command attempted" and "exact error output".
6. **Setup preflight** — `preflight.stdout` shows prerequisite verification passed and `preflight.exit` is `0`.
7. **Skill stays thin** — `skill-thin.stdout` confirms the skill file does NOT contain duplicated policy text.

## Verdict

- **PASS**: Drive workflow contains hard no-skip policy, no legacy Skip Assessment, attempt-first rules with evidence requirements, and skill remains thin.
- **FAIL**: Any policy element missing, legacy section still present, or skill duplicates policy.

Report: `PASS` or `FAIL` with evidence (search result citations).
