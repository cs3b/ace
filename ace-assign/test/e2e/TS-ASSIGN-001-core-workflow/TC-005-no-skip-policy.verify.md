# Goal 5 — No-Skip Policy Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **No-skip rule present** — `no-skip-rule.stdout` contains the mandatory no-skip policy text about planned steps being mandatory.
2. **Synthetic skip prohibited** — The prohibition against using report text to skip or synthesize completion appears in captured policy evidence (`no-skip-rule.stdout` or equivalent analysis output).
3. **Skip Assessment removed** — Search evidence or `analysis.md` confirms the old "Skip Assessment" section is absent.
4. **Attempt-first section** — `attempt-first.stdout` contains the External Action Rule (Attempt-First) section header.
5. **Evidence requirements** — Policy evidence confirms the workflow requires concrete command/evidence details, including `exact error output`; the verifier may rely on `evidence-rules.stdout`, `analysis.md`, or adjacent policy captures rather than one exact grep line.
6. **Setup preflight** — `preflight.stdout` shows prerequisite verification passed and `preflight.exit` is `0`.
7. **Skill stays thin** — `skill-thin.stdout` may be empty; empty output is acceptable evidence that the skill file does NOT duplicate policy text.

Fallback evidence rule:
- If the per-search stdout artifacts are missing, `analysis.md` may serve as the verification source when it explicitly records the no-skip rule, synthetic-skip prohibition, Skip Assessment removal, attempt-first section, evidence requirements, and thin-skill conclusion.

## Verdict

- **PASS**: Drive workflow contains hard no-skip policy, no legacy Skip Assessment, attempt-first rules with evidence requirements, and skill remains thin.
- **FAIL**: Any policy element missing, legacy section still present, or skill duplicates policy.

Report: `PASS` or `FAIL` with evidence (search result citations).
