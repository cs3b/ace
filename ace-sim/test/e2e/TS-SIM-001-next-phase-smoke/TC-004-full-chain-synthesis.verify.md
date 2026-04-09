# Goal 4 Verification: Full-Chain Final Synthesis Coverage

PASS when:
- `results/tc/04/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/04/run-tree.txt` includes `chains/codex-mini-1/01-draft/output.md`
- `results/tc/04/run-tree.txt` includes `chains/codex-mini-1/02-plan/output.md`
- `results/tc/04/run-tree.txt` includes `chains/codex-mini-1/03-work/output.md`
- `results/tc/04/run-tree.txt` includes `final/input.md`
- `results/tc/04/session.yml` contains `synthesis_workflow: wfi://task/review`
- `results/tc/04/synthesis.yml` contains `final_stage:`
- `results/tc/04/final.input.md` contains `#### Step draft`
- `results/tc/04/final.input.md` contains `#### Step plan`
- `results/tc/04/final.input.md` contains `#### Step work`
- and one of these synthesis outcomes is true:
  - success path:
    - `results/tc/04/run.exit` is `0`
    - `results/tc/04/synthesis.yml` records a successful `final_stage:`
  - recorded external failure path:
    - `results/tc/04/run.exit` is non-zero
    - `results/tc/04/run.stderr` mentions `Final synthesis failed`
    - `results/tc/04/synthesis.yml` records `final_stage:` with `status: failed`

FAIL when:
- any chain step artifact is missing
- `final/input.md` does not aggregate all three steps
- `synthesis.yml` does not record final-stage outcome
- the run fails before chain completion
