# Goal 5 Verification: Validate-Task Preset Contract

PASS when:
- `results/tc/05/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/05/run-tree.txt` includes `chains/glite-1/02-plan/input.md`
- `results/tc/05/run-tree.txt` does not include `chains/glite-1/01-draft/`
- `results/tc/05/session.yml` exists and contains `preset: validate-task`
- `results/tc/05/session.yml` contains `synthesis_workflow: wfi://task/review`
- `results/tc/05/session.yml` contains `synthesis_provider: role:sim-synthesis`
- `results/tc/05/synthesis.yml` exists and contains `final_stage:`
- plan-stage synthesis evidence exists in either `results/tc/05/final.input.md`
  or the real run directory referenced by `results/tc/05/run-dir.txt`
- and one of these execution outcomes is true:
  - success path:
    - `results/tc/05/run.exit` is `0`
    - `results/tc/05/run-tree.txt` includes `chains/glite-1/02-plan/output.md`
    - `results/tc/05/run-tree.txt` includes `chains/glite-1/03-work/input.md`
    - `results/tc/05/run-tree.txt` includes `chains/glite-1/03-work/output.md`
    - final synthesis input contains `#### Step work`, using `results/tc/05/final.input.md`
      when present or `final/input.md` in the real run dir otherwise
  - recorded external failure path:
    - `results/tc/05/run.exit` is non-zero
    - `results/tc/05/run.stderr` mentions either `Final synthesis failed` or `All chains failed`
    - `results/tc/05/synthesis.yml` records `final_stage:`
    - and one of these constrained-environment signals is true:
      - `results/tc/05/synthesis.yml` records `final_stage:` with `status: failed`
      - `results/tc/05/run.stderr` mentions `All chains failed`
        and final synthesis input contains `#### Step plan (failed)`, using `results/tc/05/final.input.md`
        when present or `final/input.md` in the real run dir otherwise
        and the same final synthesis input does not contain `#### Step work`

FAIL when:
- session preset/synthesis metadata does not match `validate-task` defaults
- run fails before plan-stage invocation evidence is produced
