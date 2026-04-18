# Goal 1: Dry-Run Public Contract

## Objective
Verify `--dry-run` executes as a non-provider run while still recording run metadata and final-stage status.

## Steps
1. Create source file `results/tc/01/source.md` with sample markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/01/source.md --provider glite --repeat 1 --dry-run`
   Save stdout/stderr/exit to:
   - `results/tc/01/run.stdout`
   - `results/tc/01/run.stderr`
   - `results/tc/01/run.exit`
3. Extract `Run Dir:` value from stdout and save it to `results/tc/01/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/01/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/01/session.yml`
   - `synthesis.yml` -> `results/tc/01/synthesis.yml`
6. Preserve recorded run artifacts exactly. Do not create placeholder files.
