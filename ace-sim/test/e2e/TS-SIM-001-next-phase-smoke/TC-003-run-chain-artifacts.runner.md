# Goal 3: Explicit CLI Override Behavior

## Objective
Verify explicit CLI custom values override preset defaults by forcing a single-step run.

## Steps
1. Create source file `results/tc/03/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/03/source.md --provider glite --steps draft --repeat 1`
   Save stdout/stderr/exit to `results/tc/03/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/03/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/03/run-tree.txt`.
5. If present, capture `session.yml`, `synthesis.yml`, and `chains/glite-1/01-draft/output.md` into `results/tc/03/`.
