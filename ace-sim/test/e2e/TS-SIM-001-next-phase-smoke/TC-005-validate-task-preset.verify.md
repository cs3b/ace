# Goal 5 Verification: Validate-Task Preset Contract

PASS when:
- `results/tc/05/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/05/run-tree.txt` includes `chains/glite-1/02-plan/input.md`
- `results/tc/05/run-tree.txt` includes `chains/glite-1/02-plan/output.md`
- `results/tc/05/run-tree.txt` includes `chains/glite-1/03-work/input.md`
- `results/tc/05/run-tree.txt` includes `chains/glite-1/03-work/output.md`
- `results/tc/05/run-tree.txt` does not include `chains/glite-1/01-draft/`
- `results/tc/05/session.yml` exists and contains `preset: validate-task`
- `results/tc/05/session.yml` contains `synthesis_workflow: wfi://task/review`
- `results/tc/05/session.yml` contains `synthesis_provider: claude:haiku`
- `results/tc/05/synthesis.yml` exists and contains `final_stage:`
- `results/tc/05/final.input.md` contains `#### Step plan`
- `results/tc/05/final.input.md` contains `#### Step work`
- and one of these synthesis outcomes is true:
  - success path:
    - `results/tc/05/run.exit` is `0`
  - recorded external failure path:
    - `results/tc/05/run.exit` is non-zero
    - `results/tc/05/run.stderr` mentions `Final synthesis failed`
    - `results/tc/05/synthesis.yml` records `final_stage:` with `status: failed`

FAIL when:
- expected plan/work chain artifacts are missing
- session preset/synthesis metadata does not match `validate-task` defaults
- run fails before chain completion evidence is produced
