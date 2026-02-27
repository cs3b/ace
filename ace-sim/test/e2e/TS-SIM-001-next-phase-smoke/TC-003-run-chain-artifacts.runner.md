# Goal 3: Preset Run and Chained Artifacts

## Objective
Execute a preset run and capture artifact layout evidence for the chained runtime.

## Steps
1. Create source file `results/tc/03/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/03/source.md --provider codex:mini --repeat 1 --dry-run`
   Save stdout/stderr/exit to `results/tc/03/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/03/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/03/run-tree.txt`.
5. If present, capture `session.yml` and `synthesis.yml` into `results/tc/03/`.
