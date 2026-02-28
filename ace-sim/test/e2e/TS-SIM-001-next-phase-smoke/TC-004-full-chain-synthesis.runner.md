# Goal 4: Full-Chain Final Synthesis Coverage

## Objective
Verify synthesis over the default full chain (`draft,plan,work`) aggregates all steps and produces both final artifacts.

## Steps
1. Create source file `results/tc/04/source.md` with realistic markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/04/source.md --provider glite --repeat 1 --synthesis-workflow wfi://task/review --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to `results/tc/04/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/04/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/04/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/04/session.yml`
   - `synthesis.yml` -> `results/tc/04/synthesis.yml`
   - `final/input.md` -> `results/tc/04/final.input.md`
   - `final/source.original.md` -> `results/tc/04/source.original.md`
   - `final/output.sequence.md` -> `results/tc/04/output.sequence.md`
   - `final/suggestions.report.md` -> `results/tc/04/suggestions.report.md`
   - `final/source.revised.md` -> `results/tc/04/source.revised.md`
