# Goal 1 Verification: Dry-Run Public Contract

PASS when:
- `results/tc/01/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/01/session.yml` exists and contains `preset: validate-idea`
- `results/tc/01/session.yml` exists and contains `dry_run: true`
- `results/tc/01/synthesis.yml` exists and contains `final_stage:`
- and one of these outcome paths is true:
  - `results/tc/01/run.exit` is `0`
  - `results/tc/01/run.exit` is non-zero and:
    - `results/tc/01/run.stderr` mentions `Final synthesis failed` or `All chains failed`
    - `results/tc/01/synthesis.yml` contains `status: failed`

FAIL when:
- dry-run metadata is not recorded in `session.yml`
- `synthesis.yml` does not record `final_stage:`
- neither outcome path is satisfied
