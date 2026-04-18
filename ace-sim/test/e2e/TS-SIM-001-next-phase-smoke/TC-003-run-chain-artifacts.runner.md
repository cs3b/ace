# Goal 3: Explicit CLI Override Behavior

## Objective
Verify explicit CLI custom values override preset defaults and run one-step final synthesis with real recorded outcomes.

## Steps
1. Create source file `results/tc/03/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/03/source.md --provider glite --steps draft --repeat 1 --synthesis-workflow wfi://idea/review --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to:
   - `results/tc/03/run.stdout`
   - `results/tc/03/run.stderr`
   - `results/tc/03/run.exit`
3. Extract `Run Dir:` value from stdout and save it to `results/tc/03/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/03/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/03/session.yml`
   - `synthesis.yml` -> `results/tc/03/synthesis.yml`
   - `chains/glite-1/01-draft/output.md` -> `results/tc/03/draft.output.md`
6. Preserve real command outcomes only. Do not create placeholder artifacts for missing synthesis output files.
