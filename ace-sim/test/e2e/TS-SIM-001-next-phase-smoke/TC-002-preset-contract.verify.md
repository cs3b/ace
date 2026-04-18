# Goal 2 Verification: Default Preset Behavioral Run

PASS when:
- `results/tc/02/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/02/run-tree.txt` includes `chains/`
- and one of these execution outcomes is true:
  - success path:
    - `results/tc/02/run.exit` is `0`
    - if `results/tc/02/session.yml` exists, it contains `preset: validate-idea`
    - if `results/tc/02/session.yml` exists, it contains `synthesis_workflow: wfi://idea/review`
    - if `results/tc/02/session.yml` exists, it contains `synthesis_provider: role:sim-synthesis`
    - `results/tc/02/run-tree.txt` includes `chains/glite-1/01-draft/output.md`
    - `results/tc/02/run-tree.txt` includes `chains/glite-1/02-plan/output.md`
    - `results/tc/02/run-tree.txt` includes `chains/glite-1/03-work/output.md`
    - `results/tc/02/output.sequence.md` exists and contains both `<suggestions-report>` and `<source-revised>`
    - `results/tc/02/suggestions.report.md` exists and is non-empty
    - `results/tc/02/source.revised.md` exists and is non-empty
  - recorded external failure path:
    - `results/tc/02/run.exit` is non-zero
    - `results/tc/02/session.yml` exists and contains `preset: validate-idea`
    - `results/tc/02/session.yml` contains `synthesis_workflow: wfi://idea/review`
    - `results/tc/02/session.yml` contains `synthesis_provider: role:sim-synthesis`
    - `results/tc/02/synthesis.yml` exists and contains `final_stage:`
    - `results/tc/02/run.stderr` mentions either `Final synthesis failed` or `All chains failed`
    - and one of these constrained-environment signals is true:
      - `results/tc/02/synthesis.yml` records `final_stage:` with `status: failed`
      - `results/tc/02/synthesis.yml` records `final_stage:` with `status: ok`
        and `results/tc/02/run.stderr` mentions `All chains failed`
        and `results/tc/02/run-tree.txt` includes `chains/`

FAIL when:
- the preset metadata in `session.yml` is present but does not match the shipped default contract
- the external failure path is used but `synthesis.yml` does not record final-stage outcome
- the run fails before any run-directory evidence is produced
