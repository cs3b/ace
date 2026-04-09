# Goal 2: Default Preset Behavioral Run

## Objective
Run the default preset flow and capture artifacts that prove the shipped preset contract and chained generation behavior are intact. If the final synthesis succeeds, capture its outputs. If it fails, preserve the recorded final-stage failure without treating that external synthesis outcome as a chain regression.

## Workspace

Save all output to `results/tc/02/`.

Capture:
- `results/tc/02/run.stdout|stderr|exit`
- `results/tc/02/run-dir.txt`
- `results/tc/02/run-tree.txt`
- `results/tc/02/session.yml`
- `results/tc/02/synthesis.yml`
- `results/tc/02/handoff-check.txt`

Optional capture:
- `results/tc/02/final.input.md` — support evidence only
- `results/tc/02/source.original.md` — support evidence only
- `results/tc/02/output.sequence.md` — support evidence only
- `results/tc/02/suggestions.report.md` — support evidence only
- `results/tc/02/source.revised.md` — support evidence only

## Steps
1. Create source file `results/tc/02/source.md` with realistic markdown task content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/02/source.md --provider codex:mini --repeat 1`
   Save stdout/stderr/exit to `results/tc/02/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/02/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/02/run-tree.txt`.
5. If present, capture `session.yml` and `synthesis.yml` into `results/tc/02/`.
6. If `run-tree.txt` shows both `chains/glite-1/01-draft/output.md` and `chains/glite-1/02-plan/input.md`, compare those two files in the run directory and write the result to `results/tc/02/handoff-check.txt`, stating whether "plan input matches draft output" or not, with a short explanation.
7. If present, capture these final synthesis files into `results/tc/02/`:
   - `final/input.md` -> `results/tc/02/final.input.md`
   - `final/source.original.md` -> `results/tc/02/source.original.md`
   - `final/output.sequence.md` -> `results/tc/02/output.sequence.md`
   - `final/suggestions.report.md` -> `results/tc/02/suggestions.report.md`
   - `final/source.revised.md` -> `results/tc/02/source.revised.md`
