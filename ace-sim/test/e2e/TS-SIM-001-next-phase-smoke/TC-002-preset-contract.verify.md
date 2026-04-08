# Goal 2 Verification: Default Preset Behavioral Run

PASS when:
- `results/tc/02/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/02/run-tree.txt` includes `chains/`
- `results/tc/02/run-tree.txt` includes `01-draft/input.md`, `01-draft/user.bundle.md`, `01-draft/user.prompt.md`, and `01-draft/output.md`
- `results/tc/02/run-tree.txt` includes `02-plan/input.md` and `02-plan/output.md`
- `results/tc/02/run-tree.txt` includes `03-work/input.md` and `03-work/output.md`
- `results/tc/02/session.yml` exists and contains `preset: validate-idea`
- `results/tc/02/session.yml` contains `synthesis_workflow: wfi://idea/review`
- `results/tc/02/session.yml` contains `synthesis_provider: role:sim-synthesis`
- `results/tc/02/synthesis.yml` exists and contains `chains:`
- `results/tc/02/handoff-check.txt` exists and indicates plan input matches draft output
- and one of these synthesis outcomes is true:
  - success path:
    - `results/tc/02/run.exit` is `0`
    - `results/tc/02/output.sequence.md` exists and contains both `<suggestions-report>` and `<source-revised>`
    - `results/tc/02/suggestions.report.md` exists and is non-empty
    - `results/tc/02/source.revised.md` exists and is non-empty
    - the copied final artifacts are the source of truth for synthesis success, not only the run-tree listing
  - recorded external failure path:
    - `results/tc/02/run.exit` is non-zero
    - `results/tc/02/run.stderr` mentions `Final synthesis failed`
    - `results/tc/02/synthesis.yml` records `final_stage:` with `status: failed`

FAIL when:
- any chain step artifact is missing
- the preset metadata in `session.yml` does not match the shipped default contract
- `handoff-check.txt` does not confirm draft output became plan input
- `synthesis.yml` does not record final-stage outcome
- the run fails before chain completion
