# Goal 3: Explicit CLI Override Behavior

## Objective
Verify explicit CLI custom values override preset defaults and produce final suggestions synthesis output.

## Steps
1. Create source file `results/tc/03/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/03/source.md --provider glite --steps draft --repeat 1 --synthesis-workflow wfi://task/review-work --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to `results/tc/03/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/03/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/03/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/03/session.yml`
   - `synthesis.yml` -> `results/tc/03/synthesis.yml`
   - `chains/glite-1/01-draft/output.md` -> `results/tc/03/draft.output.md`
   - `final/suggestions.report.md` -> `results/tc/03/suggestions.report.md`
