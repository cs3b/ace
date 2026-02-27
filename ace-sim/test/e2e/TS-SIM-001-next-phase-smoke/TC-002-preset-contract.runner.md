# Goal 2: Default Preset Behavioral Run

## Objective
Run the default preset flow end-to-end and capture artifacts that prove chained generation works.

## Steps
1. Create source file `results/tc/02/source.md` with realistic markdown task content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/02/source.md --provider glite --repeat 1`
   Save stdout/stderr/exit to `results/tc/02/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/02/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/02/run-tree.txt`.
5. If present, capture `session.yml` and `synthesis.yml` into `results/tc/02/`.
6. If present, capture these files from `chains/glite-1`:
   - `01-draft/input.md`, `01-draft/user.bundle.md`, `01-draft/user.prompt.md`, `01-draft/output.md`
   - `02-plan/input.md`, `02-plan/output.md`
7. If both files exist, compare `02-plan/input.md` with `01-draft/output.md` and save comparison result to `results/tc/02/handoff-check.txt`.
