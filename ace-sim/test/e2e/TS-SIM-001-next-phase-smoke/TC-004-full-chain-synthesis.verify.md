# Goal 4 Verification: Full-Chain Final Synthesis Coverage

PASS when:
- `results/tc/04/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/04/run-tree.txt` includes `chains/glite-1/01-draft/output.md`
- `results/tc/04/run-tree.txt` includes `chains/glite-1/02-plan/output.md`
- `results/tc/04/run-tree.txt` includes `chains/glite-1/03-work/output.md`
- `results/tc/04/run-tree.txt` includes `final/source.original.md`
- `results/tc/04/run-tree.txt` includes `final/output.sequence.md`
- `results/tc/04/run-tree.txt` includes `final/suggestions.report.md`
- `results/tc/04/run-tree.txt` includes `final/source.revised.md`
- `results/tc/04/session.yml` contains `synthesis_workflow: wfi://task/review`
- `results/tc/04/synthesis.yml` contains `final_stage:`
- and one of these synthesis outcomes is true:
  - success path:
    - `results/tc/04/run.exit` is `0`
    - `results/tc/04/output.sequence.md` contains both `<suggestions-report>` and `<source-revised>`
    - `results/tc/04/suggestions.report.md` exists and is non-empty
    - `results/tc/04/source.revised.md` exists and is non-empty
  - recorded external failure path:
    - `results/tc/04/run.exit` is non-zero
    - `results/tc/04/run.stderr` mentions `Final synthesis failed`
    - `results/tc/04/synthesis.yml` records `final_stage:` with `status: failed`

FAIL when:
- any chain step artifact is missing
- `synthesis.yml` does not record final-stage outcome
- the run fails before chain completion
