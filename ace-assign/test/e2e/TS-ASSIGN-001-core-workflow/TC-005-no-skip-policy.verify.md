# Goal 5 — No-Skip Policy Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Setup preflight** — `preflight.stdout` shows prerequisite verification passed and `preflight.exit` is `0`.
2. **No-skip rule present** — `no-skip-rule.stdout` contains the mandatory no-skip policy text about planned steps being mandatory.
3. **Attempt-first section** — `attempt-first.stdout` identifies the External Action Rule (Attempt-First) section.
4. **Evidence requirements** — `evidence-rules.stdout` shows workflow text requiring concrete command/evidence details, including exact error output.
5. **Synthetic skip prohibited / Skip Assessment removed** — command evidence confirms the workflow enforces concrete no-skip / attempt-first execution rules and no longer depends on a legacy skip-assessment path; `analysis.md` may summarize this, but it is support evidence only.
6. **Skill stays thin** — `skill-thin.stdout` confirms the skill file does NOT duplicate policy text, or `analysis.md` records that conclusion as support evidence when direct grep capture is absent.

Evidence rule:
- `analysis.md` is optional support evidence only. The primary oracle is the real grep output plus preflight captures.

## Verdict

- **PASS**: Drive workflow contains hard no-skip policy, no legacy Skip Assessment, attempt-first rules with evidence requirements, and skill remains thin.
- **FAIL**: Any policy element missing, legacy section still present, or skill duplicates policy.

Report: `PASS` or `FAIL` with evidence (search result citations).
