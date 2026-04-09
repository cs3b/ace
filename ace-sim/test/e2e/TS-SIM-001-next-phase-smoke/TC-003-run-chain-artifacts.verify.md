# Goal 3 Verification: Explicit CLI Override + One-Step Synthesis

## Provider-dependent test

This goal requires a live provider run with explicit synthesis override. The codex baseline for this scenario is `codex:mini`.

PASS when EITHER:

### Path A: Providers available (full verification)
- `results/tc/03/run.exit` is `0`
- `results/tc/03/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/03/run-tree.txt` includes `chains/`
- `results/tc/03/run-tree.txt` includes `chains/codex-mini-1/01-draft/input.md` and `chains/codex-mini-1/01-draft/output.md`
- `results/tc/03/run-tree.txt` includes `chains/codex-mini-1/01-draft/user.bundle.md` and `chains/codex-mini-1/01-draft/user.prompt.md`
- `results/tc/03/run-tree.txt` does not include `02-plan/`
- `results/tc/03/run-tree.txt` does not include `03-work/`
- `results/tc/03/run-tree.txt` does not include `chains/codex-mini-1/02-plan/output.md`
- `results/tc/03/run-tree.txt` does not include `chains/codex-mini-1/03-work/output.md`
- `results/tc/03/run-tree.txt` includes `final/source.original.md`
- `results/tc/03/run-tree.txt` includes `final/output.sequence.md`
- `results/tc/03/run-tree.txt` includes `final/suggestions.report.md`
- `results/tc/03/run-tree.txt` includes `final/source.revised.md`
- `results/tc/03/session.yml` exists and contains `preset: validate-idea`
- `results/tc/03/session.yml` contains `steps:` with only `draft`
- `results/tc/03/session.yml` contains `synthesis_workflow: wfi://idea/review`
- `results/tc/03/session.yml` contains `synthesis_provider: codex:mini`
- `results/tc/03/synthesis.yml` exists and contains `final_stage:`

### Path B: Provider unavailable (conditional pass)
- `results/tc/03/run.exit` is non-zero
- `results/tc/03/run.stderr` mentions `Final synthesis failed`
- `results/tc/03/synthesis.yml` records `final_stage:` with `status: failed`
- Verdict: PASS with note "provider unavailable — CLI invocation and argument routing verified, LLM execution skipped"

FAIL when:
- Neither Path A nor Path B conditions are met
